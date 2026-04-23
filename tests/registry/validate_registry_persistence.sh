#!/usr/bin/env bash

# FILE: tests/registry/validate_registry_persistence.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that registry persistence uses the expected DETS lookup and insert operations.
#   SCOPE: Static checks for DETS read/write calls and directory preparation.
#   DEPENDS: apps/kpproton_proxy/src/registry/kpproton_registry.erl
#   LINKS: M-REGISTRY, V-M-REGISTRY
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required persistence patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for registry persistence verification.
# END_CHANGE_SUMMARY

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

## START_BLOCK_VALIDATE_REGISTRY_PERSISTENCE
[[ -f "${FILE}" ]] || fail "missing registry contract"
require_pattern 'dets:lookup\(Table, Email\)'
require_pattern 'dets:insert\(Table, \{Email, Assignment\}\)'
require_pattern 'filelib:ensure_dir\(Path\)'
## END_BLOCK_VALIDATE_REGISTRY_PERSISTENCE

echo "[M-REGISTRY][save_user][WRITE_ASSIGNMENT] ok"
