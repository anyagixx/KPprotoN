#!/usr/bin/env bash
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

[[ -f "${FILE}" ]] || fail "missing kpproton_core_api.erl"
require_pattern 'filter_proxy_config'
require_pattern 'BOOTSTRAP_DOWNSTREAM_CONNECT_TIMEOUT_MS'
require_pattern 'filtered unreachable downstream'
require_pattern 'gen_tcp:connect'

echo "[M-PROXY-BRIDGE][apply_domain_policy][LOAD_POLICY] bootstrap-filter-ok"
