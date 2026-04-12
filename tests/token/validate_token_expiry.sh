#!/usr/bin/env bash
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

[[ -f "${FILE}" ]] || fail "missing token store"
require_pattern 'expires_at'
require_pattern '\{error, expired\}'
require_pattern '\[M-TOKEN\]\[expire\]\[PURGE_EXPIRED\]'
require_pattern 'maps:filter'

echo "[M-TOKEN][expire][PURGE_EXPIRED] ok"
