#!/usr/bin/env bash

# FILE: tests/provisioning/validate_proxy_issue_contract.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate the provisioning contract for SNI generation and tg-link assembly.
#   SCOPE: Static checks for exports, SNI hashing, derived credential markers, and issued link structure.
#   DEPENDS: apps/kpproton_proxy/src/provisioning/kpproton_proxy_issue.erl
#   LINKS: M-PROXY-ISSUE, V-M-PROXY-ISSUE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required proxy-issue patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for proxy-issue contract verification.
# END_CHANGE_SUMMARY

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

## START_BLOCK_VALIDATE_PROXY_ISSUE_CONTRACT
[[ -f "${FILE}" ]] || fail "missing proxy issue contract"
require_pattern '-export\(\[generate_sni/2, build_tg_link/5, issue_proxy_for_email/6\]\)'
require_pattern 'crypto:hash\(sha256, Email\)'
require_pattern 'tg://proxy\?server='
require_pattern 'policy_action => apply_domain_policy'
require_pattern 'credential_mode => derived_per_sni'
require_pattern '\[M-PROXY-ISSUE\]\[issue_proxy_for_email\]\[BUILD_TG_LINK\]'
require_pattern 'binary:part\(HashHex, 0, 12\)'
require_pattern 'mtp_fake_tls:derive_sni_secret'
## END_BLOCK_VALIDATE_PROXY_ISSUE_CONTRACT

echo "[M-PROXY-ISSUE][issue_proxy_for_email][GENERATE_SNI] ok"
