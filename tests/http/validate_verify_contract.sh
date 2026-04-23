#!/usr/bin/env bash

# FILE: tests/http/validate_verify_contract.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate the verify handler contract for token consumption and success-page rendering.
#   SCOPE: Static checks for exports, log markers, issuance wiring, and key verify copy.
#   DEPENDS: apps/kpproton_portal/src/http/kpproton_verify_handler.erl
#   LINKS: M-WEB-API, V-M-WEB-API
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required verify-handler patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for verify-handler verification.
# END_CHANGE_SUMMARY

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

## START_BLOCK_VALIDATE_VERIFY_HANDLER
[[ -f "${FILE}" ]] || fail "missing verify handler"
require_pattern '^%% coding: utf-8$'
require_pattern '-export\(\[init/2, render_verify_result/1\]\)'
require_pattern '\[M-WEB-API\]\[verify_token\]\[CONSUME_TOKEN\]'
require_pattern '\[M-WEB-API\]\[verify_token\]\[RENDER_RESULT\]'
require_pattern 'Ссылка недействительна'
require_pattern 'Прокси готов'
require_pattern 'tg://proxy'
require_pattern 'kpproton_registry:open_registry'
require_pattern 'kpproton_runtime:proxy_secret_salt\(\)'
## END_BLOCK_VALIDATE_VERIFY_HANDLER

echo "[M-WEB-API][verify_token][RENDER_RESULT] ok"
