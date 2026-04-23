#!/usr/bin/env bash

# FILE: tests/http/validate_http_negative_paths.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that request and verify handlers keep the expected negative-path copy.
#   SCOPE: Static checks for invalid email, invalid token, expired token, and generic verification failure branches.
#   DEPENDS: apps/kpproton_portal/src/http/kpproton_request_handler.erl, apps/kpproton_portal/src/http/kpproton_verify_handler.erl
#   LINKS: M-WEB-API, V-M-WEB-API
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   none - uses direct grep checks against the request and verify handlers
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for negative-path HTTP verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REQ_FILE="${ROOT_DIR}/apps/kpproton_portal/src/http/kpproton_request_handler.erl"
VERIFY_FILE="${ROOT_DIR}/apps/kpproton_portal/src/http/kpproton_verify_handler.erl"

fail() {
  echo "[M-WEB-API][verify_token][RENDER_RESULT] $*" >&2
  exit 1
}

## START_BLOCK_VALIDATE_NEGATIVE_PATHS
grep -Eq -- 'invalid_email' "${REQ_FILE}" || fail "missing invalid email path"
grep -Eq -- 'Ссылка недействительна' "${VERIFY_FILE}" || fail "missing invalid token path"
grep -Eq -- 'Срок действия ссылки истёк' "${VERIFY_FILE}" || fail "missing expired token path"
grep -Eq -- 'Ошибка верификации' "${VERIFY_FILE}" || fail "missing generic verification error path"
## END_BLOCK_VALIDATE_NEGATIVE_PATHS

echo "[M-WEB-API][verify_token][RENDER_RESULT] negative-paths-ok"
