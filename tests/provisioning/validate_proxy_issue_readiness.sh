#!/usr/bin/env bash

# FILE: tests/provisioning/validate_proxy_issue_readiness.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate readiness of proxy issuance for deterministic SNI and derived tg-link construction.
#   SCOPE: Static checks for truncation, derivation, reuse, and encoded port handling.
#   DEPENDS: apps/kpproton_proxy/src/provisioning/kpproton_proxy_issue.erl
#   LINKS: M-PROXY-ISSUE, V-M-PROXY-ISSUE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   none - performs direct grep checks against the provisioning module
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for proxy-issue readiness verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_proxy/src/provisioning/kpproton_proxy_issue.erl"

fail() {
  echo "[M-PROXY-ISSUE][issue_proxy_for_email][BUILD_TG_LINK] $*" >&2
  exit 1
}

## START_BLOCK_VALIDATE_PROXY_ISSUE_READINESS
grep -Eq -- 'binary:part\(HashHex, 0, 12\)' "${FILE}" || fail "missing deterministic SNI truncation"
grep -Eq -- 'binary:decode_hex\(SecretHex\)' "${FILE}" || fail "missing base secret decoding for derivation"
grep -Eq -- 'mtp_fake_tls:derive_sni_secret\(BaseSecret, SniDomain, SecretSalt\)' "${FILE}" || fail "missing per-SNI secret derivation"
grep -Eq -- 'mtp_fake_tls:format_secret_hex\(DerivedSecret, SniDomain\)' "${FILE}" || fail "missing derived fake-TLS formatting"
grep -Eq -- 'policy_action => apply_domain_policy' "${FILE}" || fail "missing apply action"
grep -Eq -- 'policy_action => reuse' "${FILE}" || fail "missing idempotent reuse action"
grep -Eq -- 'integer_to_binary\(Port\)' "${FILE}" || fail "missing port encoding in tg link"
## END_BLOCK_VALIDATE_PROXY_ISSUE_READINESS

echo "[M-PROXY-ISSUE][issue_proxy_for_email][BUILD_TG_LINK] readiness-ok"
