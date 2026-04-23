#!/usr/bin/env bash

# FILE: tests/mtproto/validate_bootstrap_filter.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that the core bootstrap filter keeps unreachable downstreams out of the exposed config surface.
#   SCOPE: Static checks for filtering hooks, timeout wiring, and downstream connectivity probing.
#   DEPENDS: src/kpproton_core_api.erl
#   LINKS: M-PROXY-BRIDGE, V-M-PROXY-BRIDGE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required bootstrap-filter patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for bootstrap filter verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/src/kpproton_core_api.erl"

fail() {
  echo "[M-PROXY-BRIDGE][apply_domain_policy][LOAD_POLICY] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

## START_BLOCK_VALIDATE_BOOTSTRAP_FILTER
[[ -f "${FILE}" ]] || fail "missing kpproton_core_api.erl"
require_pattern 'filter_proxy_config'
require_pattern 'BOOTSTRAP_DOWNSTREAM_CONNECT_TIMEOUT_MS'
require_pattern 'filtered unreachable downstream'
require_pattern 'gen_tcp:connect'
## END_BLOCK_VALIDATE_BOOTSTRAP_FILTER

echo "[M-PROXY-BRIDGE][apply_domain_policy][LOAD_POLICY] bootstrap-filter-ok"
