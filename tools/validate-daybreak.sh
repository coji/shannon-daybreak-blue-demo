#!/usr/bin/env bash

set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SHANNON_COMMIT="2468b67d9e40d70d0b189462c5041c24e1dc886c"
readonly CACHE_ROOT="${XDG_CACHE_HOME:-${HOME}/.cache}/shannon-daybreak-blue-demo"
readonly SHANNON_DIR="${CACHE_ROOT}/shannon-${SHANNON_COMMIT:0:7}"
readonly SHANNON="${SHANNON_DIR}/shannon"
readonly AUTH_FILE="${HOME}/.pi/agent/auth.json"

[[ -x "${SHANNON}" ]] || { echo "Run npm run shannon:build first." >&2; exit 1; }
jq -e '.openai.type == "oauth"' "${AUTH_FILE}" >/dev/null || {
  echo "Pi has no OpenAI ChatGPT OAuth login. Run /login in Pi first." >&2
  exit 1
}

unset OPENAI_API_KEY OPENAI_BASE_URL SHANNON_AI_API_KEY SHANNON_AI_BASE_URL
export SHANNON_USE_PI_AUTH=1
export SHANNON_AI_MODEL="${SHANNON_MODEL:-openai:gpt-6-sol}"

(
  cd "${SHANNON_DIR}"
  "${SHANNON}" start \
    --url http://host.docker.internal:4173 \
    --repo "${REPO_ROOT}" \
    --validate-model
)
