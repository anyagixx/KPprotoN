#!/usr/bin/env bash
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

[[ -f "${FILE}" ]] || fail "missing proxy issue contract"
require_pattern '#\{tg_link := _\} = Assignment'
require_pattern 'policy_action => reuse'
require_pattern 'sni => SniDomain'
require_pattern 'tg_link => TgLink'

echo "[M-PROXY-ISSUE][issue_proxy_for_email][PERSIST_ASSIGNMENT] ok"
