#!/usr/bin/env bash
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

[[ -f "${FILE}" ]] || fail "missing token store"
require_pattern '-export\(\[create_token/3, consume_token/3, purge_expired/2\]\)'
require_pattern 'crypto:strong_rand_bytes'
require_pattern '\[M-TOKEN\]\[create\]\[STORE_TOKEN\]'
require_pattern '\[M-TOKEN\]\[consume\]\[DELETE_TOKEN\]'
require_pattern 'maps:remove'
require_pattern '\{ok, Record, maps:remove'

echo "[M-TOKEN][create][STORE_TOKEN] ok"
