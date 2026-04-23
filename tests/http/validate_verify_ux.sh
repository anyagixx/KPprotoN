#!/usr/bin/env bash

# FILE: tests/http/validate_verify_ux.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate the shipped verify UX affordances around copy buttons, manual fields, and newest-link messaging.
#   SCOPE: Static checks for verify HTML copy plus the coupled JS and CSS assets.
#   DEPENDS: apps/kpproton_portal/src/http/kpproton_verify_handler.erl, apps/kpproton_portal/priv/static/verify.js, apps/kpproton_portal/priv/static/styles.css
#   LINKS: M-WEB-API, V-M-WEB-API
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required verify UX patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for verify UX verification.
# END_CHANGE_SUMMARY

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

## START_BLOCK_VALIDATE_VERIFY_UX
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
## END_BLOCK_VALIDATE_VERIFY_UX

echo "[M-WEB-API][verify_token][RENDER_RESULT] verify-ux-ok"
