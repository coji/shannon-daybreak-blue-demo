# Shannon + Daybreak Blue demo

ShannonをChatGPT SubscriptionのDaybreak Blueで動かす最小デモです。Shannon 3.4.0が内蔵するPi 0.84.4を、ローカルビルド時だけPi 1.2.0へ更新します。Shannon本体への変更やPRは必要ありません。

> [!WARNING]
> このアプリには、Shannonの検出確認用として反射型XSSと所有権確認漏れを意図的に入れています。ローカルのテストデータだけで動かしてください。公開サーバーへデプロイしないでください。

## 必要なもの

- macOSまたはLinux
- Node.js 22以降
- Docker
- Git、jq、curl、Corepack
- Pi 1.2.0以降
- Daybreak Blueを利用できるChatGPTアカウント

Piで`/login`を実行し、`Sign in with an account`から`OpenAI`へログインしておきます。

## 実行

```bash
npm test
npm run shannon:build
```

ターミナル1でデモアプリを起動します。

```bash
HOST=0.0.0.0 npm start
```

`0.0.0.0`で起動すると、同じLANの別端末から到達できる場合があります。信頼できるネットワークだけで実行し、スキャン後は停止してください。

ターミナル2でDaybreak Blueの認証とモデルを検証します。

```bash
npm run shannon:validate
```

検証が通ったら、同じターミナルで分析専用スキャンを開始します。

```bash
npm run shannon:scan
```

失敗したworkspaceを使い直すと、Shannonは途中状態から再開します。最初からやり直す場合は、別の名前を指定してください。

```bash
SHANNON_WORKSPACE=daybreak-blue-run-2 npm run shannon:scan
```

Shannonへ渡す既定のモデルは`openai:gpt-daybreak-blue-latest`です。`tools/shannon.yaml`では`exploit: 'false'`にしており、実証攻撃は行いません。

意図的に脆弱なローカルデモに限り、別workspaceで最小限の実証攻撃を含むスキャンも実行できます。

```bash
SHANNON_WORKSPACE=daybreak-blue-exploit-run-1 npm run shannon:scan:exploit
```

`tools/shannon-exploit.yaml`は`exploit: 'true'`ですが、架空のメモリーデータだけを対象にし、破壊、永続化、総当たり、DoS、外部コールバック、データ持ち出しを禁止しています。公開環境や第三者のシステムには使わないでください。

比較実験では`SHANNON_MODEL`でモデルだけを上書きできます。

```bash
SHANNON_MODEL=openai:gpt-6.1-sol npm run shannon:validate
SHANNON_MODEL=openai:gpt-6.1-sol SHANNON_WORKSPACE=gpt-6-1-sol-run npm run shannon:scan
```

スキャンは`shannon:validate`が成功した場合だけ実行してください。別モデルの結果が既定workspaceへ混ざらないよう、既定以外のモデルでは`SHANNON_WORKSPACE`の指定を必須にしています。2026年10月14日の検証では、`gpt-6.1-sol`のCyber Access確認が`OpenAiCyberAccessError`で失敗したため、フルスキャンは開始していません。Daybreak Blueは同じ認証と対象でCyber Access確認を通過し、全工程を完走しました。

## 検証結果

2026年10月14日に、Daybreak Blueで分析専用スキャンと攻撃検証スキャンの全工程を完走しました。

分析専用スキャン:

- 所要時間: 51分4秒
- Shannonの表示コスト: $19.5633
- 実行agent: 8（skipなし）
- 検出結果: 反射型XSS、認証の欠落、オブジェクト所有権チェックの欠落
- 実証攻撃: 無効

攻撃検証スキャン:

- 所要時間: 54分20秒
- Shannonの表示コスト: $19.5194
- 実行agent: 11（Injection ExploitとSSRF Exploitは対象なしでskip）
- 実証結果: 反射型XSS、匿名でのノート取得、他ユーザーのノート取得を再現
- 最終レポート: 3件ともLow。デモデータが架空で、書き込みや削除を行わない構成であることを反映
- 安全境界: DOM置換とlocalStorageへのマーカー書き込み、架空ノートの読み取りまで。破壊、永続化、外部コールバック、DoSは未実施

外部キャッシュへ切り替えた構成で、再試行なしに全工程が完了しました。レポートは`${XDG_CACHE_HOME:-$HOME/.cache}/shannon-daybreak-blue-demo/shannon-2468b67/workspaces/<workspace>/`に生成されます。

## 仕組み

`tools/build-shannon.sh`はShannonの特定コミットを`${XDG_CACHE_HOME:-$HOME/.cache}/shannon-daybreak-blue-demo/`の下へcloneし、次の3パッケージだけを1.2.0へ更新してローカルworkerイメージを作ります。コミットごとに別のディレクトリを使うため、更新時に既存の変更済みcheckoutと衝突しません。

- `@earendil-works/pi-agent-core`
- `@earendil-works/pi-ai`
- `@earendil-works/pi-coding-agent`

pnpmの`minimumReleaseAge`は無効にせず、これらが依存する`@earendil-works/pi-*`だけを`minimumReleaseAgeExclude`へ追加します。

Shannon 3.4.0の標準workerはPi 0.84.4を使うため、Pi 0.99.0で追加されたOpenAIのChatGPT OAuthとDaybreak Blueを扱えません。Pi 1.2.0へ更新すると、`openai:gpt-daybreak-blue-latest`のモデル検証とCyber Access確認が通ります。

## 安全上の境界

- 対象は`host.docker.internal:4173`に固定しています。
- デモデータはメモリー上の架空データだけです。
- Shannonのcheckoutとレポートは対象リポジトリの外に置き、過去のスキャン結果を次のスキャンへ混入させません。
- ローカルで生成される`.cache`、`.playwright`、`.shannon`、`workspaces`はGit管理から除外します。
- 通常のスキャン設定は分析専用です。攻撃検証用の設定も、意図的に脆弱なこのローカルデモだけを対象にします。
- 認証ファイル`~/.pi/agent/auth.json`をリポジトリへコピーしません。
