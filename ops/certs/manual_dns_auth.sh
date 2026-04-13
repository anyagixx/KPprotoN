#!/usr/bin/env bash

# FILE: ops/certs/manual_dns_auth.sh
# VERSION: 1.2.0
# START_MODULE_CONTRACT
#   PURPOSE: Guide the operator through manual DNS-01 TXT creation and block until the TXT is publicly visible.
#   SCOPE: Render exact `_acme-challenge` instructions, wait for Enter, verify propagation with dig, and only then return control to Certbot.
#   DEPENDS: certbot manual hook environment, dnsutils
#   LINKS: M-CERTS, M-INSTALL
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   log_line - emits structured manual DNS progress markers
#   txt_values - returns currently visible TXT values for the challenge FQDN
#   txt_visible - checks if the expected TXT value is visible via public DNS
#   wait_for_operator_confirmation - loops until the operator confirms and TXT propagation is observed through /dev/tty
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.2.0 - Clarified multi-challenge TXT behavior and print current DNS TXT values when propagation is still incomplete.
# END_CHANGE_SUMMARY

set -euo pipefail

TTY_DEVICE="/dev/tty"

log_line() {
  local block="$1"
  shift
  printf '[M-CERTS][bootstrap][%s] %s\n' "${block}" "$*"
}

fail() {
  log_line "ERROR" "$*"
  exit 1
}

txt_values() {
  local fqdn="$1"
  dig +short TXT "${fqdn}" 2>/dev/null || true
}

txt_visible() {
  local fqdn="$1"
  local value="$2"
  local output=""

  output="$(txt_values "${fqdn}")"
  grep -Fq "\"${value}\"" <<<"${output}"
}

wait_for_operator_confirmation() {
  local fqdn="$1"
  local value="$2"

  [[ -r "${TTY_DEVICE}" && -w "${TTY_DEVICE}" ]] || fail "interactive terminal is required for guided manual DNS-01"

  while true; do
    {
      printf '\n'
      printf 'Add the following DNS TXT record and wait until it is publicly visible:\n'
      printf '  Name : %s\n' "${fqdn}"
      printf '  Type : TXT\n'
      printf '  Value: %s\n' "${value}"
      printf '\n'
      printf 'This prompt can appear more than once for the same TXT name. That is normal for apex + wildcard issuance.\n'
      printf 'If the TXT name already exists, keep existing values and add this one as an additional TXT value.\n'
      printf 'Press Enter after you have added the TXT record and verified propagation: '
    } >"${TTY_DEVICE}"
    read -r _ <"${TTY_DEVICE}"

    if txt_visible "${fqdn}" "${value}"; then
      log_line "REQUEST_CERT" "confirmed TXT propagation for ${fqdn}"
      return 0
    fi

    {
      printf '\nCurrent public TXT values for %s:\n' "${fqdn}"
      txt_values "${fqdn}"
      printf '\nExpected TXT value still not visible.\n'
    } >"${TTY_DEVICE}"
    log_line "REQUEST_CERT" "TXT value not visible yet for ${fqdn}; waiting for another confirmation round"
  done
}

command -v dig >/dev/null 2>&1 || fail "dig is required for guided manual DNS-01 checks"
[[ -n "${CERTBOT_DOMAIN:-}" ]] || fail "CERTBOT_DOMAIN is not set"
[[ -n "${CERTBOT_VALIDATION:-}" ]] || fail "CERTBOT_VALIDATION is not set"

FQDN="_acme-challenge.${CERTBOT_DOMAIN}"
wait_for_operator_confirmation "${FQDN}" "${CERTBOT_VALIDATION}"
