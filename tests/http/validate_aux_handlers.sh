#!/usr/bin/env bash

# FILE: tests/http/validate_aux_handlers.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate source-contract coverage for auxiliary HTTP handlers that sit beside `/api/request` and `/verify`.
#   SCOPE: Static checks for health and bootstrap handlers, including contract markers, exports, and core call wiring.
#   DEPENDS: apps/kpproton_portal/src/http/kpproton_health_handler.erl, apps/kpproton_portal/src/http/kpproton_bootstrap_config_handler.erl, apps/kpproton_portal/src/http/kpproton_bootstrap_secret_handler.erl
#   LINKS: M-WEB-API, V-M-WEB-API
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required auxiliary-handler patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added deterministic contract checks for health and bootstrap HTTP handlers.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HEALTH_FILE="${ROOT_DIR}/apps/kpproton_portal/src/http/kpproton_health_handler.erl"
CONFIG_FILE="${ROOT_DIR}/apps/kpproton_portal/src/http/kpproton_bootstrap_config_handler.erl"
SECRET_FILE="${ROOT_DIR}/apps/kpproton_portal/src/http/kpproton_bootstrap_secret_handler.erl"

fail() {
  echo "[M-WEB-API][verify_token][RENDER_RESULT] $*" >&2
  exit 1
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  grep -Eq -- "${pattern}" "${file}" || fail "missing pattern in ${file}: ${pattern}"
}

## START_BLOCK_VALIDATE_AUX_HANDLERS
[[ -f "${HEALTH_FILE}" ]] || fail "missing kpproton_health_handler.erl"
[[ -f "${CONFIG_FILE}" ]] || fail "missing kpproton_bootstrap_config_handler.erl"
[[ -f "${SECRET_FILE}" ]] || fail "missing kpproton_bootstrap_secret_handler.erl"

require_pattern "${HEALTH_FILE}" 'START_MODULE_CONTRACT'
require_pattern "${HEALTH_FILE}" 'START_BLOCK_INIT'
require_pattern "${HEALTH_FILE}" 'END_BLOCK_INIT'
require_pattern "${HEALTH_FILE}" '-export\(\[init/2\]\)'
require_pattern "${HEALTH_FILE}" 'kpproton_request_handler:health_response'

require_pattern "${CONFIG_FILE}" 'START_MODULE_CONTRACT'
require_pattern "${CONFIG_FILE}" 'START_BLOCK_INIT'
require_pattern "${CONFIG_FILE}" 'END_BLOCK_INIT'
require_pattern "${CONFIG_FILE}" 'kpproton_core_api:proxy_config'
require_pattern "${CONFIG_FILE}" 'bootstrap config unavailable'

require_pattern "${SECRET_FILE}" 'START_MODULE_CONTRACT'
require_pattern "${SECRET_FILE}" 'START_BLOCK_INIT'
require_pattern "${SECRET_FILE}" 'END_BLOCK_INIT'
require_pattern "${SECRET_FILE}" 'kpproton_core_api:proxy_secret'
require_pattern "${SECRET_FILE}" 'bootstrap secret unavailable'
## END_BLOCK_VALIDATE_AUX_HANDLERS

echo "[M-WEB-API][verify_token][RENDER_RESULT] aux-handlers-ok"
