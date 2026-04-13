#!/usr/bin/env bash

# FILE: tests/certs/validate_cert_strategy.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that certificate provisioning uses an explicit wildcard-safe DNS-01 strategy.
#   SCOPE: Static checks for manual DNS challenge, wildcard domain request, export/import helper presence, and mount contract logging.
#   DEPENDS: ops/certs/provision-certs.sh
#   LINKS: M-CERTS, V-M-CERTS
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required strategy markers exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.3.0 - Removed REG.RU automation expectations and validated the single guided manual DNS-01 strategy.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CERT_SCRIPT="${ROOT_DIR}/ops/certs/provision-certs.sh"
EXPORT_SCRIPT="${ROOT_DIR}/ops/certs/export-existing-cert.sh"
IMPORT_SCRIPT="${ROOT_DIR}/ops/certs/import-existing-cert.sh"

fail() {
  echo "[M-CERTS][bootstrap][SELECT_CHALLENGE] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${CERT_SCRIPT}" || fail "missing pattern: ${pattern}"
}

[[ -f "${CERT_SCRIPT}" ]] || fail "missing provision-certs.sh"
[[ -f "${EXPORT_SCRIPT}" ]] || fail "missing export-existing-cert.sh"
[[ -f "${IMPORT_SCRIPT}" ]] || fail "missing import-existing-cert.sh"
require_pattern '--preferred-challenges dns'
require_pattern '--manual'
require_pattern '--manual-auth-hook'
require_pattern 'manual_dns_auth.sh'
require_pattern 'manual_dns_cleanup.sh'
require_pattern '\*.\$\{BASE_DOMAIN\}'
require_pattern 'log_line "PERSIST_PATHS"'
require_pattern 'request_manual_dns_cert'
grep -Eq 'fullchain\.pem' "${EXPORT_SCRIPT}" || fail "export helper does not package fullchain.pem"
grep -Eq 'privkey\.pem' "${EXPORT_SCRIPT}" || fail "export helper does not package privkey.pem"
grep -Eq '/etc/letsencrypt/live/' "${IMPORT_SCRIPT}" || fail "import helper does not target letsencrypt live path"

echo "[M-CERTS][bootstrap][SELECT_CHALLENGE] ok"
