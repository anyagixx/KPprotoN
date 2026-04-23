#!/usr/bin/env bash

# FILE: tests/resend/validate_resend_errors.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate the provider-error mapping surface for the Resend adapter.
#   SCOPE: Static checks for 401, 429, provider_unavailable, and timeout mappings.
#   DEPENDS: apps/kpproton_portal/src/integrations/resend/kpproton_resend_adapter.erl
#   LINKS: M-EMAIL, V-M-EMAIL
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required provider-error mapping patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for Resend error verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/src/integrations/resend/kpproton_resend_adapter.erl"

fail() {
  echo "[M-EMAIL][send_magic_link][MAP_PROVIDER_ERROR] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

## START_BLOCK_VALIDATE_RESEND_ERRORS
[[ -f "${FILE}" ]] || fail "missing resend adapter"
require_pattern '401'
require_pattern 'invalid_api_key'
require_pattern '429'
require_pattern 'rate_limited'
require_pattern 'provider_unavailable'
require_pattern 'timeout'
## END_BLOCK_VALIDATE_RESEND_ERRORS

echo "[M-EMAIL][send_magic_link][MAP_PROVIDER_ERROR] ok"
