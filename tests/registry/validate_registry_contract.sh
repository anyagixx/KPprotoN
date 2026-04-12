#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_proxy/src/registry/kpproton_registry.erl"

fail() {
  echo "[M-REGISTRY][open][OPEN_DETS] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

[[ -f "${FILE}" ]] || fail "missing registry contract"
require_pattern '-export\(\[open_registry/1, lookup_user/2, save_user/3, close_registry/1\]\)'
require_pattern 'kpproton_registry'
require_pattern '\[M-REGISTRY\]\[open\]\[OPEN_DETS\]'
require_pattern '\[M-REGISTRY\]\[lookup_user\]\[LOOKUP_EMAIL\]'
require_pattern '\[M-REGISTRY\]\[save_user\]\[WRITE_ASSIGNMENT\]'
require_pattern 'dets:open_file'

echo "[M-REGISTRY][open][OPEN_DETS] ok"
