#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_proxy/src/registry/kpproton_registry.erl"

fail() {
  echo "[M-REGISTRY][save_user][WRITE_ASSIGNMENT] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

[[ -f "${FILE}" ]] || fail "missing registry contract"
require_pattern 'dets:lookup\(Table, Email\)'
require_pattern 'dets:insert\(Table, \{Email, Assignment\}\)'
require_pattern 'filelib:ensure_dir\(Path\)'

echo "[M-REGISTRY][save_user][WRITE_ASSIGNMENT] ok"
