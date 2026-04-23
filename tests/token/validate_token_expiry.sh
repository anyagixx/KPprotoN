#!/usr/bin/env bash

# FILE: tests/token/validate_token_expiry.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate the token-store expiry and purge semantics.
#   SCOPE: Static checks for expiration markers, expired outcome, purge log marker, and map filtering.
#   DEPENDS: apps/kpproton_portal/src/token/kpproton_token_store.erl
#   LINKS: M-TOKEN, V-M-TOKEN
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required token-expiry patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for token-expiry verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/src/token/kpproton_token_store.erl"

fail() {
  echo "[M-TOKEN][expire][PURGE_EXPIRED] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

## START_BLOCK_VALIDATE_TOKEN_EXPIRY
[[ -f "${FILE}" ]] || fail "missing token store"
require_pattern 'expires_at'
require_pattern '\{error, expired\}'
require_pattern '\[M-TOKEN\]\[expire\]\[PURGE_EXPIRED\]'
require_pattern 'maps:filter'
## END_BLOCK_VALIDATE_TOKEN_EXPIRY

echo "[M-TOKEN][expire][PURGE_EXPIRED] ok"
