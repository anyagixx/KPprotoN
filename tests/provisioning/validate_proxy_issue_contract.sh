#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_proxy/src/provisioning/kpproton_proxy_issue.erl"

fail() {
  echo "[M-PROXY-ISSUE][issue_proxy_for_email][GENERATE_SNI] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

[[ -f "${FILE}" ]] || fail "missing proxy issue contract"
require_pattern '-export\(\[generate_sni/2, build_tg_link/5, issue_proxy_for_email/6\]\)'
require_pattern 'crypto:hash\(sha256, Email\)'
require_pattern 'tg://proxy\?server='
require_pattern 'policy_action => apply_domain_policy'
require_pattern 'credential_mode => derived_per_sni'
require_pattern '\[M-PROXY-ISSUE\]\[issue_proxy_for_email\]\[BUILD_TG_LINK\]'
require_pattern 'binary:part\(HashHex, 0, 12\)'
require_pattern 'mtp_fake_tls:derive_sni_secret'

echo "[M-PROXY-ISSUE][issue_proxy_for_email][GENERATE_SNI] ok"
