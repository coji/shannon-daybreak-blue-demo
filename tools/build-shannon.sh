#!/usr/bin/env bash

set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SHANNON_DIR="${REPO_ROOT}/.cache/shannon"
readonly SHANNON_COMMIT="2468b67d9e40d70d0b189462c5041c24e1dc886c"

for command_name in docker git node corepack; do
  command -v "${command_name}" >/dev/null || { echo "Missing command: ${command_name}" >&2; exit 1; }
done

if [[ ! -d "${SHANNON_DIR}/.git" ]]; then
  mkdir -p "$(dirname "${SHANNON_DIR}")"
  git clone https://github.com/KeygraphHQ/shannon.git "${SHANNON_DIR}"
fi

git -C "${SHANNON_DIR}" fetch origin "${SHANNON_COMMIT}"
git -C "${SHANNON_DIR}" checkout --detach "${SHANNON_COMMIT}"

node --input-type=module - "${SHANNON_DIR}/apps/worker/package.json" <<'NODE'
import fs from 'node:fs'

const file = process.argv[2]
const json = JSON.parse(fs.readFileSync(file, 'utf8'))
for (const name of [
  '@earendil-works/pi-agent-core',
  '@earendil-works/pi-ai',
  '@earendil-works/pi-coding-agent',
]) {
  json.dependencies[name] = '1.2.0'
}
fs.writeFileSync(file, `${JSON.stringify(json, null, 2)}\n`)
NODE

(
  cd "${SHANNON_DIR}"
  corepack pnpm install --no-frozen-lockfile --config.minimumReleaseAge=0
  corepack pnpm --filter @shannon/worker exec tsc
  corepack pnpm --filter @keygraph/shannon exec tsdown
  ./shannon build
)

echo "Built patched Shannon with Pi 1.2.0 at ${SHANNON_DIR}"
