#!/usr/bin/env bash

# FILE: tests/registry/validate_registry_contract.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate the DETS registry contract for open, lookup, and save wiring.
#   SCOPE: Static checks for exports, log markers, and DETS open semantics.
#   DEPENDS: apps/kpproton_proxy/src/registry/kpproton_registry.erl
#   LINKS: M-REGISTRY, V-M-REGISTRY
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required registry patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for registry contract verification.
# END_CHANGE_SUMMARY

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

## START_BLOCK_VALIDATE_REGISTRY_CONTRACT
[[ -f "${FILE}" ]] || fail "missing registry contract"
require_pattern '-export\(\[open_registry/1, lookup_user/2, save_user/3, close_registry/1\]\)'
require_pattern 'kpproton_registry'
require_pattern '\[M-REGISTRY\]\[open\]\[OPEN_DETS\]'
require_pattern '\[M-REGISTRY\]\[lookup_user\]\[LOOKUP_EMAIL\]'
require_pattern '\[M-REGISTRY\]\[save_user\]\[WRITE_ASSIGNMENT\]'
require_pattern 'dets:open_file'
## END_BLOCK_VALIDATE_REGISTRY_CONTRACT

echo "[M-REGISTRY][open][OPEN_DETS] ok"
