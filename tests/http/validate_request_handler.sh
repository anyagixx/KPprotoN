#!/usr/bin/env bash

# FILE: tests/http/validate_request_handler.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate the request handler contract for accepted email submissions and health payload wiring.
#   SCOPE: Static checks for exports, validation markers, and shipped Russian response copy.
#   DEPENDS: apps/kpproton_portal/src/http/kpproton_request_handler.erl
#   LINKS: M-WEB-API, V-M-WEB-API
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required request-handler patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for request-handler verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/src/http/kpproton_request_handler.erl"

fail() {
  echo "[M-WEB-API][request_email][VALIDATE_INPUT] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

## START_BLOCK_VALIDATE_REQUEST_HANDLER
[[ -f "${FILE}" ]] || fail "missing request handler"
require_pattern '^%% coding: utf-8$'
require_pattern '-export\(\[init/2, validate_email/1, handle_request/1, health_response/0\]\)'
require_pattern 'invalid_email'
require_pattern '\[M-WEB-API\]\[request_email\]\[VALIDATE_INPUT\]'
require_pattern '\[M-WEB-API\]\[request_email\]\[DISPATCH_EMAIL\]'
require_pattern 'Проверьте почту'
require_pattern 'jsx:decode'
## END_BLOCK_VALIDATE_REQUEST_HANDLER

echo "[M-WEB-API][request_email][VALIDATE_INPUT] ok"
