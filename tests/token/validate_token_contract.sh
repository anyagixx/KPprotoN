#!/usr/bin/env bash

# FILE: tests/token/validate_token_contract.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate the token-store contract for create, consume, and delete semantics.
#   SCOPE: Static checks for exports, entropy source, log markers, and token removal behavior.
#   DEPENDS: apps/kpproton_portal/src/token/kpproton_token_store.erl
#   LINKS: M-TOKEN, V-M-TOKEN
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required token-store patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for token-store verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/src/token/kpproton_token_store.erl"

fail() {
  echo "[M-TOKEN][create][STORE_TOKEN] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

## START_BLOCK_VALIDATE_TOKEN_CONTRACT
[[ -f "${FILE}" ]] || fail "missing token store"
require_pattern '-export\(\[create_token/3, consume_token/3, purge_expired/2\]\)'
require_pattern 'crypto:strong_rand_bytes'
require_pattern '\[M-TOKEN\]\[create\]\[STORE_TOKEN\]'
require_pattern '\[M-TOKEN\]\[consume\]\[DELETE_TOKEN\]'
require_pattern 'maps:remove'
require_pattern '\{ok, Record, maps:remove'
## END_BLOCK_VALIDATE_TOKEN_CONTRACT

echo "[M-TOKEN][create][STORE_TOKEN] ok"
