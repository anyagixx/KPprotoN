#!/usr/bin/env bash

# FILE: tests/certs/validate_cert_strategy.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that certificate provisioning uses an explicit wildcard-safe DNS-01 strategy.
#   SCOPE: Static checks for manual DNS challenge, wildcard domain request, and mount contract logging.
#   DEPENDS: ops/certs/provision-certs.sh
#   LINKS: M-CERTS, V-M-CERTS
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required strategy markers exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.2.0 - Added guided manual DNS-01 hook validation alongside REG.RU automation.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CERT_SCRIPT="${ROOT_DIR}/ops/certs/provision-certs.sh"

fail() {
  echo "[M-CERTS][bootstrap][SELECT_CHALLENGE] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${CERT_SCRIPT}" || fail "missing pattern: ${pattern}"
}

[[ -f "${CERT_SCRIPT}" ]] || fail "missing provision-certs.sh"
require_pattern '--preferred-challenges dns'
require_pattern '--manual'
require_pattern '--manual-auth-hook'
require_pattern 'reg_ru_dns_auth.sh'
require_pattern 'reg_ru_dns_cleanup.sh'
require_pattern 'manual_dns_auth.sh'
require_pattern 'manual_dns_cleanup.sh'
require_pattern '\*.\$\{BASE_DOMAIN\}'
require_pattern 'log_line "PERSIST_PATHS"'

echo "[M-CERTS][bootstrap][SELECT_CHALLENGE] ok"
