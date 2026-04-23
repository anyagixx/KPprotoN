#!/usr/bin/env bash

# FILE: tests/mtproto/validate_bridge_module.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that the MTProto bridge module exposes the expected apply-domain hook into policy state.
#   SCOPE: Static checks for export surface, log markers, and mtp_policy_table integration.
#   DEPENDS: apps/kpproton_proxy/src/mtproto/kpproton_proxy_bridge.erl
#   LINKS: M-PROXY-BRIDGE, V-M-PROXY-BRIDGE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   none - performs direct grep checks against the bridge module
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for MTProto bridge verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_proxy/src/mtproto/kpproton_proxy_bridge.erl"

fail() {
  echo "[M-PROXY-BRIDGE][apply_domain_policy][APPLY_POLICY] $*" >&2
  exit 1
}

## START_BLOCK_VALIDATE_BRIDGE_MODULE
grep -Eq -- '-export\(\[apply_domain_policy/1\]\)' "${FILE}" || fail "missing apply_domain_policy export"
grep -Eq -- '\[M-PROXY-BRIDGE\]\[apply_domain_policy\]\[LOAD_POLICY\]' "${FILE}" || fail "missing load policy log"
grep -Eq -- '\[M-PROXY-BRIDGE\]\[apply_domain_policy\]\[APPLY_POLICY\]' "${FILE}" || fail "missing apply policy log"
grep -Eq -- 'mtp_policy_table:add\(personal_domains, tls_domain, SniDomain\)' "${FILE}" || fail "missing mtproto policy table integration"
## END_BLOCK_VALIDATE_BRIDGE_MODULE

echo "[M-PROXY-BRIDGE][apply_domain_policy][APPLY_POLICY] ok"
