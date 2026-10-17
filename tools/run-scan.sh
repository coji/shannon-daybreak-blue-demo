#!/usr/bin/env bash

set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SHANNON_COMMIT="2468b67d9e40d70d0b189462c5041c24e1dc886c"
readonly CACHE_ROOT="${XDG_CACHE_HOME:-${HOME}/.cache}/shannon-daybreak-blue-demo"
readonly SHANNON_DIR="${CACHE_ROOT}/shannon-${SHANNON_COMMIT:0:7}"
readonly SHANNON="${SHANNON_DIR}/shannon"
readonly DEFAULT_MODEL="openai:gpt-6-sol"
readonly MODEL="${SHANNON_MODEL:-${DEFAULT_MODEL}}"
readonly WORKSPACE="${SHANNON_WORKSPACE:-shannon-daybreak-blue-demo}"
readonly CONFIG_INPUT="${SHANNON_CONFIG:-tools/shannon.yaml}"
if [[ "${CONFIG_INPUT}" = /* ]]; then
  readonly CONFIG="${CONFIG_INPUT}"
else
  readonly CONFIG="${REPO_ROOT}/${CONFIG_INPUT}"
fi

[[ -x "${SHANNON}" ]] || { echo "Run npm run shannon:build first." >&2; exit 1; }
[[ -f "${CONFIG}" ]] || { echo "Shannon config not found: ${CONFIG}" >&2; exit 1; }
if [[ "${MODEL}" != "${DEFAULT_MODEL}" && -z "${SHANNON_WORKSPACE:-}" ]]; then
  echo "Set SHANNON_WORKSPACE when comparing a non-default model." >&2
  exit 1
fi
curl --fail --silent --show-error --max-time 5 http://127.0.0.1:4173/ >/dev/null || {
  echo "Start the demo first: HOST=0.0.0.0 npm start" >&2
  exit 1
}

unset OPENAI_API_KEY OPENAI_BASE_URL SHANNON_AI_API_KEY SHANNON_AI_BASE_URL
export SHANNON_USE_PI_AUTH=1
export SHANNON_AI_MODEL="${MODEL}"

(
  cd "${SHANNON_DIR}"
  "${SHANNON}" start \
    --url http://host.docker.internal:4173 \
    --repo "${REPO_ROOT}" \
    --workspace "${WORKSPACE}" \
    --config "${CONFIG}" \
    --follow
)
