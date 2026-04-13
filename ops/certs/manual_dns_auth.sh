#!/usr/bin/env bash

# FILE: ops/certs/manual_dns_auth.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Guide the operator through manual DNS-01 TXT creation and block until the TXT is publicly visible.
#   SCOPE: Render exact `_acme-challenge` instructions, wait for Enter, verify propagation with dig, and only then return control to Certbot.
#   DEPENDS: certbot manual hook environment, dnsutils
#   LINKS: M-CERTS, M-INSTALL
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   log_line - emits structured manual DNS progress markers
#   txt_visible - checks if the expected TXT value is visible via public DNS
#   wait_for_operator_confirmation - loops until the operator confirms and TXT propagation is observed
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added guided manual DNS-01 auth hook with Enter-to-continue and propagation verification.
# END_CHANGE_SUMMARY

set -euo pipefail

log_line() {
  local block="$1"
  shift
  printf '[M-CERTS][bootstrap][%s] %s\n' "${block}" "$*"
}

fail() {
  log_line "ERROR" "$*"
  exit 1
}

txt_visible() {
  local fqdn="$1"
  local value="$2"
  local output=""

  output="$(dig +short TXT "${fqdn}" 2>/dev/null || true)"
  grep -Fq "\"${value}\"" <<<"${output}"
}

wait_for_operator_confirmation() {
  local fqdn="$1"
  local value="$2"

  while true; do
    printf '\n'
    printf 'Add the following DNS TXT record and wait until it is publicly visible:\n'
    printf '  Name : %s\n' "${fqdn}"
    printf '  Type : TXT\n'
    printf '  Value: %s\n' "${value}"
    printf '\n'
    printf 'If the TXT name already exists, keep existing values and add this one as an additional TXT value.\n'
    read -r -p 'Press Enter after you have added the TXT record and verified propagation: ' _

    if txt_visible "${fqdn}" "${value}"; then
      log_line "REQUEST_CERT" "confirmed TXT propagation for ${fqdn}"
      return 0
    fi

    log_line "REQUEST_CERT" "TXT value not visible yet for ${fqdn}; waiting for another confirmation round"
  done
}

command -v dig >/dev/null 2>&1 || fail "dig is required for guided manual DNS-01 checks"
[[ -n "${CERTBOT_DOMAIN:-}" ]] || fail "CERTBOT_DOMAIN is not set"
[[ -n "${CERTBOT_VALIDATION:-}" ]] || fail "CERTBOT_VALIDATION is not set"

FQDN="_acme-challenge.${CERTBOT_DOMAIN}"
wait_for_operator_confirmation "${FQDN}" "${CERTBOT_VALIDATION}"
