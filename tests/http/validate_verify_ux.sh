#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/src/http/kpproton_verify_handler.erl"
JS_FILE="${ROOT_DIR}/apps/kpproton_portal/priv/static/verify.js"
CSS_FILE="${ROOT_DIR}/apps/kpproton_portal/priv/static/styles.css"

fail() {
  echo "[M-WEB-API][verify_token][RENDER_RESULT] $*" >&2
  exit 1
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  grep -Eq -- "${pattern}" "${file}" || fail "missing pattern in ${file}: ${pattern}"
}

[[ -f "${FILE}" ]] || fail "missing verify handler"
[[ -f "${JS_FILE}" ]] || fail "missing verify.js"
[[ -f "${CSS_FILE}" ]] || fail "missing styles.css"

require_pattern "${FILE}" 'Открыть в Telegram'
require_pattern "${FILE}" 'Скопировать tg://proxy'
require_pattern "${FILE}" 'Используйте только эту ссылку и этот Secret'
require_pattern "${FILE}" 'Добавить прокси → MTProto'
require_pattern "${FILE}" 'manual-server'
require_pattern "${FILE}" 'manual-port'
require_pattern "${FILE}" 'manual-secret'
require_pattern "${FILE}" '/static/verify\.js'
require_pattern "${JS_FILE}" 'data-copy'
require_pattern "${CSS_FILE}" 'result-shell'
require_pattern "${CSS_FILE}" 'copy-button'

echo "[M-WEB-API][verify_token][RENDER_RESULT] verify-ux-ok"
