#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/src/http/kpproton_verify_handler.erl"

fail() {
  echo "[M-WEB-API][verify_token][RENDER_RESULT] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

[[ -f "${FILE}" ]] || fail "missing verify handler"
require_pattern '^%% coding: utf-8$'
require_pattern '-export\(\[init/2, render_verify_result/1\]\)'
require_pattern '\[M-WEB-API\]\[verify_token\]\[CONSUME_TOKEN\]'
require_pattern '\[M-WEB-API\]\[verify_token\]\[RENDER_RESULT\]'
require_pattern 'Ссылка недействительна'
require_pattern 'Прокси готов'
require_pattern 'tg://proxy'
require_pattern 'kpproton_registry:open_registry'

echo "[M-WEB-API][verify_token][RENDER_RESULT] ok"
