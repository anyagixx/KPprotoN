#!/usr/bin/env bash

# FILE: ops/certs/manual_dns_cleanup.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Complete the guided manual DNS-01 flow without forcing immediate TXT cleanup.
#   SCOPE: Emit an operator-facing note after Certbot challenge completion.
#   DEPENDS: certbot manual hook environment
#   LINKS: M-CERTS
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   log_line - emits structured cleanup markers
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added no-op cleanup hook for guided manual DNS-01 workflow.
# END_CHANGE_SUMMARY

set -euo pipefail

log_line() {
  local block="$1"
  shift
  printf '[M-CERTS][bootstrap][%s] %s\n' "${block}" "$*"
}

log_line "REQUEST_CERT" "manual DNS-01 challenge completed for ${CERTBOT_DOMAIN:-unknown-domain}; TXT cleanup can be done after issuance if desired"
