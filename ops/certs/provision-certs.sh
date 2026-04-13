#!/usr/bin/env bash

# FILE: ops/certs/provision-certs.sh
# VERSION: 1.2.0
# START_MODULE_CONTRACT
#   PURPOSE: Provision apex and wildcard TLS certificates for KPprotoN through a guided manual DNS-01 flow.
#   SCOPE: Install Certbot if missing, read base domain and cert email, request certs through guided manual DNS-01, and persist mount contract notes.
#   DEPENDS: .env
#   LINKS: M-CERTS, M-INSTALL, V-M-CERTS
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   log_line - emits structured certificate bootstrap messages
#   require_base_domain - loads BASE_DOMAIN from args or env file
#   install_certbot - installs Certbot on Ubuntu when absent
#   request_manual_dns_cert - runs Certbot with guided manual DNS challenge flow
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.3.0 - Simplified certificate issuance to a single guided manual DNS-01 path and removed REG.RU automation branches.
# END_CHANGE_SUMMARY

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DOMAIN="${1:-}"
ENV_FILE="${2:-}"
MANUAL_AUTH_HOOK="${SCRIPT_DIR}/manual_dns_auth.sh"
MANUAL_CLEANUP_HOOK="${SCRIPT_DIR}/manual_dns_cleanup.sh"
CERTBOT_EMAIL=""

log_line() {
  local block="$1"
  shift
  printf '[M-CERTS][bootstrap][%s] %s\n' "${block}" "$*"
}

fail() {
  log_line "ERROR" "$*"
  exit 1
}

run_privileged() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

require_base_domain() {
  if [[ -z "${BASE_DOMAIN}" && -n "${ENV_FILE}" && -f "${ENV_FILE}" ]]; then
    BASE_DOMAIN="$(grep -E '^BASE_DOMAIN=' "${ENV_FILE}" | head -n1 | cut -d'=' -f2-)"
  fi
  [[ -n "${BASE_DOMAIN}" ]] || fail "BASE_DOMAIN is required"
}

load_certbot_email() {
  if [[ -n "${ENV_FILE}" && -f "${ENV_FILE}" ]]; then
    CERTBOT_EMAIL="$(grep -E '^TLS_CERTBOT_EMAIL=' "${ENV_FILE}" | head -n1 | cut -d'=' -f2-)"
  fi
  [[ -n "${CERTBOT_EMAIL}" ]] || CERTBOT_EMAIL="admin@${BASE_DOMAIN}"
}

install_certbot() {
  if command -v certbot >/dev/null 2>&1 && command -v dig >/dev/null 2>&1; then
    log_line "SELECT_CHALLENGE" "certbot and dig already installed"
    return 0
  fi
  log_line "SELECT_CHALLENGE" "installing certbot dependencies for DNS-01 workflow"
  run_privileged apt-get update
  run_privileged apt-get install -y certbot dnsutils
}

request_manual_dns_cert() {
  [[ -f "${MANUAL_AUTH_HOOK}" ]] || fail "missing guided manual DNS auth hook"
  [[ -f "${MANUAL_CLEANUP_HOOK}" ]] || fail "missing guided manual DNS cleanup hook"

  log_line "SELECT_CHALLENGE" "using guided manual DNS-01 because wildcard certificates require DNS validation"
  log_line "REQUEST_CERT" "installer will print TXT records, wait for Enter, verify propagation, and then continue"
  log_line "PERSIST_PATHS" "expected mount path: /etc/letsencrypt/live/${BASE_DOMAIN}/"

  run_privileged certbot certonly \
      --manual \
      --preferred-challenges dns \
      --manual-auth-hook "bash ${MANUAL_AUTH_HOOK}" \
      --manual-cleanup-hook "bash ${MANUAL_CLEANUP_HOOK}" \
      --manual-public-ip-logging-ok \
      --non-interactive \
      --agree-tos \
      --email "${CERTBOT_EMAIL}" \
      --keep-until-expiring \
      -d "${BASE_DOMAIN}" \
      -d "*.${BASE_DOMAIN}"
}

# START_BLOCK_SELECT_CHALLENGE
require_base_domain
load_certbot_email
install_certbot
# END_BLOCK_SELECT_CHALLENGE

# START_BLOCK_REQUEST_CERT
request_manual_dns_cert
# END_BLOCK_REQUEST_CERT

# START_BLOCK_PERSIST_PATHS
log_line "PERSIST_PATHS" "certificate material ready for bind mount into /certs"
# END_BLOCK_PERSIST_PATHS
