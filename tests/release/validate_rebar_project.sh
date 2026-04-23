#!/usr/bin/env bash

# FILE: tests/release/validate_rebar_project.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that release build metadata and config entry files exist and stay source-governed.
#   SCOPE: Presence checks for release inputs, dependency declarations, and MyGRACE contract markers in rebar/sys.config surfaces.
#   DEPENDS: rebar.config, config/sys.config, src/kpproton.app.src, src/kpproton_app.erl, src/kpproton_web.erl
#   LINKS: M-RELEASE, V-M-RELEASE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   none - performs direct file and grep checks against release inputs
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for release project verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() {
  echo "[M-RELEASE][build][FETCH_DEPS] $*" >&2
  exit 1
}

## START_BLOCK_VALIDATE_RELEASE_PROJECT
[[ -f "${ROOT_DIR}/rebar.config" ]] || fail "missing rebar.config"
[[ -f "${ROOT_DIR}/src/kpproton.app.src" ]] || fail "missing application descriptor"
[[ -f "${ROOT_DIR}/src/kpproton_app.erl" ]] || fail "missing OTP app module"
[[ -f "${ROOT_DIR}/src/kpproton_web.erl" ]] || fail "missing web runtime module"
[[ -f "${ROOT_DIR}/tests/release/validate_per_sni_runtime_config.sh" ]] || fail "missing per-SNI runtime validation"
[[ -f "${ROOT_DIR}/tests/release/validate_utf8_runtime_copy.sh" ]] || fail "missing UTF-8 runtime validation"

grep -Eq -- 'cowboy' "${ROOT_DIR}/rebar.config" || fail "cowboy dependency missing"
grep -Eq -- 'jsx' "${ROOT_DIR}/rebar.config" || fail "jsx dependency missing"
grep -Eq -- 'START_MODULE_CONTRACT' "${ROOT_DIR}/rebar.config" || fail "rebar.config missing source contract"
grep -Eq -- 'START_BLOCK_PROJECT_CONFIG' "${ROOT_DIR}/rebar.config" || fail "rebar.config missing semantic block"
grep -Eq -- 'END_BLOCK_PROJECT_CONFIG' "${ROOT_DIR}/rebar.config" || fail "rebar.config missing semantic block end"
grep -Eq -- 'START_MODULE_CONTRACT' "${ROOT_DIR}/config/sys.config" || fail "config/sys.config missing source contract"
grep -Eq -- 'START_BLOCK_RUNTIME_SYS_CONFIG' "${ROOT_DIR}/config/sys.config" || fail "config/sys.config missing semantic block"
grep -Eq -- 'END_BLOCK_RUNTIME_SYS_CONFIG' "${ROOT_DIR}/config/sys.config" || fail "config/sys.config missing semantic block end"
## END_BLOCK_VALIDATE_RELEASE_PROJECT

echo "[M-RELEASE][build][FETCH_DEPS] rebar-project-ok"
