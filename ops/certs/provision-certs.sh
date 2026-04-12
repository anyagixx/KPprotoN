#!/usr/bin/env bash

# FILE: ops/certs/provision-certs.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Provision apex and wildcard TLS certificates for KPprotoN through REG.RU DNS-01 automation with manual fallback.
#   SCOPE: Install Certbot if missing, read base domain and cert email, detect REG.RU credentials, request certs through DNS hooks or manual DNS-01, and persist mount contract notes.
#   DEPENDS: .env
#   LINKS: M-CERTS, M-INSTALL, V-M-CERTS
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   log_line - emits structured certificate bootstrap messages
#   require_base_domain - loads BASE_DOMAIN from args or env file
#   install_certbot - installs Certbot on Ubuntu when absent
#   request_reg_ru_dns_cert - runs Certbot with REG.RU DNS-01 hook automation
#   request_manual_dns_cert - runs Certbot with explicit manual DNS challenge flow
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.1.0 - Added REG.RU DNS-01 automation path with root-owned credential file fallback.
# END_CHANGE_SUMMARY

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DOMAIN="${1:-}"
ENV_FILE="${2:-}"
REGRU_CREDENTIALS_FILE="${REGRU_CREDENTIALS_FILE:-/etc/kpproton/reg.ru.credentials}"
AUTH_HOOK="${SCRIPT_DIR}/reg_ru_dns_auth.sh"
CLEANUP_HOOK="${SCRIPT_DIR}/reg_ru_dns_cleanup.sh"
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
  if command -v certbot >/dev/null 2>&1; then
    log_line "SELECT_CHALLENGE" "certbot already installed"
    return 0
  fi
  log_line "SELECT_CHALLENGE" "installing certbot for manual DNS-01 workflow"
  run_privileged apt-get update
  run_privileged apt-get install -y certbot
}

has_reg_ru_credentials() {
  [[ -f "${REGRU_CREDENTIALS_FILE}" ]] || return 1
  grep -Eq '^REGRU_API_USERNAME=' "${REGRU_CREDENTIALS_FILE}" &&
    grep -Eq '^REGRU_API_PASSWORD=' "${REGRU_CREDENTIALS_FILE}"
}

request_reg_ru_dns_cert() {
  [[ -x "${AUTH_HOOK}" ]] || fail "missing REG.RU auth hook"
  [[ -x "${CLEANUP_HOOK}" ]] || fail "missing REG.RU cleanup hook"

  log_line "SELECT_CHALLENGE" "using REG.RU DNS-01 automation"
  log_line "REQUEST_CERT" "requesting wildcard certificate via REG.RU API hooks"
  log_line "PERSIST_PATHS" "expected mount path: /etc/letsencrypt/live/${BASE_DOMAIN}/"

  run_privileged env \
      REGRU_CREDENTIALS_FILE="${REGRU_CREDENTIALS_FILE}" \
      BASE_DOMAIN="${BASE_DOMAIN}" \
      certbot certonly \
      --manual \
      --preferred-challenges dns \
      --manual-auth-hook "${AUTH_HOOK}" \
      --manual-cleanup-hook "${CLEANUP_HOOK}" \
      --manual-public-ip-logging-ok \
      --non-interactive \
      --agree-tos \
      --email "${CERTBOT_EMAIL}" \
      --keep-until-expiring \
      -d "${BASE_DOMAIN}" \
      -d "*.${BASE_DOMAIN}"
}

request_manual_dns_cert() {
  log_line "SELECT_CHALLENGE" "using manual DNS-01 because wildcard certificates require DNS validation"
  log_line "REQUEST_CERT" "create TXT records for _acme-challenge.${BASE_DOMAIN} when certbot prompts"
  log_line "PERSIST_PATHS" "expected mount path: /etc/letsencrypt/live/${BASE_DOMAIN}/"

  run_privileged certbot certonly \
    --manual \
    --preferred-challenges dns \
    --manual-public-ip-logging-ok \
    --agree-tos \
    --email "${CERTBOT_EMAIL}" \
    -d "${BASE_DOMAIN}" \
    -d "*.${BASE_DOMAIN}"
}

# START_BLOCK_SELECT_CHALLENGE
require_base_domain
load_certbot_email
install_certbot
# END_BLOCK_SELECT_CHALLENGE

# START_BLOCK_REQUEST_CERT
if has_reg_ru_credentials; then
  request_reg_ru_dns_cert
else
  request_manual_dns_cert
fi
# END_BLOCK_REQUEST_CERT

# START_BLOCK_PERSIST_PATHS
log_line "PERSIST_PATHS" "certificate material ready for bind mount into /certs"
# END_BLOCK_PERSIST_PATHS
