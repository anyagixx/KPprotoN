#!/usr/bin/env bash

# FILE: tests/release/validate_release_wrapper.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate the release wrapper script that stages and copies back the assembled prod release.
#   SCOPE: Static checks for ASCII-safe stage path, relx invocation, and sync-back step.
#   DEPENDS: scripts/build_release.sh
#   LINKS: M-RELEASE, V-M-RELEASE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   none - performs direct grep checks against the release wrapper script
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for release wrapper verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/scripts/build_release.sh"

fail() {
  echo "[M-RELEASE][build][ASSEMBLE_RELEASE] $*" >&2
  exit 1
}

## START_BLOCK_VALIDATE_RELEASE_WRAPPER
[[ -f "${FILE}" ]] || fail "missing scripts/build_release.sh"

grep -Eq -- '/tmp/kpproton_release_ascii' "${FILE}" || fail "missing ASCII stage directory"
grep -Eq -- 'rebar3 as prod release' "${FILE}" || fail "missing relx invocation"
grep -Eq -- 'cp -a "\$\{STAGE_DIR\}/_build/prod/rel/kpproton"' "${FILE}" || fail "missing sync-back step"
## END_BLOCK_VALIDATE_RELEASE_WRAPPER

echo "[M-RELEASE][build][ASSEMBLE_RELEASE] wrapper-ok"
