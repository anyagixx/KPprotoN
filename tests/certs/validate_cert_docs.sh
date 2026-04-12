#!/usr/bin/env bash

# FILE: tests/certs/validate_cert_docs.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that the operator-facing certificate documentation preserves the mount contract and DNS-01 rationale.
#   SCOPE: Static checks for README wording around wildcard constraints and runtime paths.
#   DEPENDS: ops/certs/README.md
#   LINKS: M-CERTS, V-M-CERTS
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts a required documentation statement exists
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.1.0 - Updated documentation validation for REG.RU automation plus manual DNS-01 fallback.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
README_FILE="${ROOT_DIR}/ops/certs/README.md"

fail() {
  echo "[M-CERTS][bootstrap][PERSIST_PATHS] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq "${pattern}" "${README_FILE}" || fail "missing pattern: ${pattern}"
}

[[ -f "${README_FILE}" ]] || fail "missing ops/certs/README.md"
require_pattern 'REG.RU DNS-01 automation'
require_pattern 'Manual Fallback'
require_pattern 'cannot be issued through plain HTTP-01'
require_pattern '/certs/live/<BASE_DOMAIN>/fullchain.pem'
require_pattern '/etc/letsencrypt'

echo "[M-CERTS][bootstrap][PERSIST_PATHS] ok"
