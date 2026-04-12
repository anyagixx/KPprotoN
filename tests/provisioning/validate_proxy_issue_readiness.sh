#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_proxy/src/provisioning/kpproton_proxy_issue.erl"

fail() {
  echo "[M-PROXY-ISSUE][issue_proxy_for_email][BUILD_TG_LINK] $*" >&2
  exit 1
}

grep -Eq -- 'binary:part\(HashHex, 0, 12\)' "${FILE}" || fail "missing deterministic SNI truncation"
grep -Eq -- 'policy_action => apply_domain_policy' "${FILE}" || fail "missing apply action"
grep -Eq -- 'policy_action => reuse' "${FILE}" || fail "missing idempotent reuse action"
grep -Eq -- 'integer_to_binary\(Port\)' "${FILE}" || fail "missing port encoding in tg link"

echo "[M-PROXY-ISSUE][issue_proxy_for_email][BUILD_TG_LINK] readiness-ok"
