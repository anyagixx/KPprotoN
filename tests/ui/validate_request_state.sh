#!/usr/bin/env bash

# FILE: tests/ui/validate_request_state.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate the request-state frontend wiring for submit, success, and error transitions.
#   SCOPE: Static checks for request.js fetch path, UI log markers, and success/error state transitions.
#   DEPENDS: apps/kpproton_portal/priv/static/request.js
#   LINKS: M-WEB-UI, V-M-WEB-UI
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required request-state patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for request-state UI verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/priv/static/request.js"

fail() {
  echo "[M-WEB-UI][submit][REQUEST_PROXY] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

## START_BLOCK_VALIDATE_REQUEST_STATE
[[ -f "${FILE}" ]] || fail "missing request.js"
require_pattern 'fetch\("/api/request"'
require_pattern '\[M-WEB-UI\]\[submit\]\[REQUEST_PROXY\]'
require_pattern '\[M-WEB-UI\]\[state\]\[SHOW_CHECK_EMAIL\]'
require_pattern '\[M-WEB-UI\]\[state\]\[SHOW_ERROR\]'
require_pattern 'setStatus\("success"'
## END_BLOCK_VALIDATE_REQUEST_STATE

echo "[M-WEB-UI][submit][REQUEST_PROXY] ok"
