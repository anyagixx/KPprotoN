#!/usr/bin/env bash

# FILE: tests/release/validate_entrypoint.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that the foundational container entrypoint retains required runtime boot behaviors.
#   SCOPE: Checks for structured logs, directory bootstrap, and placeholder command dispatch.
#   DEPENDS: docker/entrypoint.sh
#   LINKS: M-RELEASE, V-M-RELEASE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts that a required entrypoint behavior is present
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added deterministic entrypoint contract validation.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENTRYPOINT_FILE="${ROOT_DIR}/docker/entrypoint.sh"

fail() {
  echo "[M-RELEASE][boot][START_RUNTIME] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq "${pattern}" "${ENTRYPOINT_FILE}" || fail "missing pattern: ${pattern}"
}

# START_BLOCK_VALIDATE_ENTRYPOINT
[[ -f "${ENTRYPOINT_FILE}" ]] || fail "missing docker/entrypoint.sh"
require_pattern '\[M-RELEASE\]\[boot\]\['
require_pattern 'ensure_dir "\$\{DETS_DATA_DIR\}"'
require_pattern 'ensure_dir "\$\{TOKEN_DATA_DIR\}"'
require_pattern 'foundation-ready'
# END_BLOCK_VALIDATE_ENTRYPOINT

echo "[M-RELEASE][boot][START_RUNTIME] ok"
