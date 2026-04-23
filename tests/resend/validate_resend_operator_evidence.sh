#!/usr/bin/env bash

# FILE: tests/resend/validate_resend_operator_evidence.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that operator-facing evidence keeps the expected mapped Resend failure tuples.
#   SCOPE: Static checks for invalid_api_key, rate_limited, provider_unavailable, and timeout tuples.
#   DEPENDS: apps/kpproton_portal/src/integrations/resend/kpproton_resend_adapter.erl
#   LINKS: M-EMAIL, V-M-EMAIL
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   none - performs direct grep checks against mapped Resend tuples
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for Resend operator-evidence verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/src/integrations/resend/kpproton_resend_adapter.erl"

fail() {
  echo "[M-EMAIL][send_magic_link][MAP_PROVIDER_ERROR] $*" >&2
  exit 1
}

## START_BLOCK_VALIDATE_RESEND_OPERATOR_EVIDENCE
grep -Eq -- '\{error, invalid_api_key\}' "${FILE}" || fail "missing 401 mapping"
grep -Eq -- '\{error, rate_limited\}' "${FILE}" || fail "missing 429 mapping"
grep -Eq -- '\{error, provider_unavailable\}' "${FILE}" || fail "missing 5xx mapping"
grep -Eq -- '\{error, timeout\}' "${FILE}" || fail "missing timeout mapping"
## END_BLOCK_VALIDATE_RESEND_OPERATOR_EVIDENCE

echo "[M-EMAIL][send_magic_link][MAP_PROVIDER_ERROR] operator-evidence-ok"
