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
#   LAST_CHANGE: v1.4.0 - Updated documentation validation for manual-only DNS-01 issuance and certificate reuse workflow.
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
require_pattern 'guided manual DNS-01'
require_pattern 'cannot be issued through plain HTTP-01'
require_pattern 'press `Enter`'
require_pattern 'publicly visible via `dig`'
require_pattern '/certs/live/<BASE_DOMAIN>/fullchain.pem'
require_pattern '/etc/letsencrypt'
require_pattern 'export-existing-cert.sh'
require_pattern 'import-existing-cert.sh'
require_pattern 'Let’s Encrypt issuance limits'

echo "[M-CERTS][bootstrap][PERSIST_PATHS] ok"
