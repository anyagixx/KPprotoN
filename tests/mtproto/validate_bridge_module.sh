#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_proxy/src/mtproto/kpproton_proxy_bridge.erl"

fail() {
  echo "[M-PROXY-BRIDGE][apply_domain_policy][APPLY_POLICY] $*" >&2
  exit 1
}

grep -Eq -- '-export\(\[apply_domain_policy/1\]\)' "${FILE}" || fail "missing apply_domain_policy export"
grep -Eq -- '\[M-PROXY-BRIDGE\]\[apply_domain_policy\]\[LOAD_POLICY\]' "${FILE}" || fail "missing load policy log"
grep -Eq -- '\[M-PROXY-BRIDGE\]\[apply_domain_policy\]\[APPLY_POLICY\]' "${FILE}" || fail "missing apply policy log"
grep -Eq -- 'mtp_policy_table:add\(personal_domains, tls_domain, SniDomain\)' "${FILE}" || fail "missing mtproto policy table integration"

echo "[M-PROXY-BRIDGE][apply_domain_policy][APPLY_POLICY] ok"
