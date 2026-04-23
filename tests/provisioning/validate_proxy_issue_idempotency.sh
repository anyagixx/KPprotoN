#!/usr/bin/env bash

# FILE: tests/provisioning/validate_proxy_issue_idempotency.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that provisioning reuses existing assignments instead of creating divergent records.
#   SCOPE: Static checks for reuse-path patterns and canonical tg-link rebuilding.
#   DEPENDS: apps/kpproton_proxy/src/provisioning/kpproton_proxy_issue.erl
#   LINKS: M-PROXY-ISSUE, V-M-PROXY-ISSUE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required idempotency patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for proxy-issue idempotency verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_proxy/src/provisioning/kpproton_proxy_issue.erl"

fail() {
  echo "[M-PROXY-ISSUE][issue_proxy_for_email][PERSIST_ASSIGNMENT] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

## START_BLOCK_VALIDATE_PROXY_ISSUE_IDEMPOTENCY
[[ -f "${FILE}" ]] || fail "missing proxy issue contract"
require_pattern '#\{sni := ExistingSni\} = Assignment'
require_pattern 'credential_mode => derived_per_sni'
require_pattern 'policy_action => reuse'
require_pattern 'sni => SniDomain'
require_pattern 'tg_link => TgLink'
## END_BLOCK_VALIDATE_PROXY_ISSUE_IDEMPOTENCY

echo "[M-PROXY-ISSUE][issue_proxy_for_email][PERSIST_ASSIGNMENT] ok"
