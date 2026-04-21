#!/usr/bin/env bash

# FILE: install.sh
# VERSION: 1.5.0
# START_MODULE_CONTRACT
#   PURPOSE: Bootstrap a clean Ubuntu host into a runnable KPprotoN deployment with minimal operator input.
#   SCOPE: Collect domain and Resend API key, install Docker tooling, generate shared env, prepare storage, either provision or import certificates, and start compose.
#   DEPENDS: deploy/.env.example, ops/certs/provision-certs.sh, docker-compose.yml
#   LINKS: M-INSTALL, M-CONFIG, M-CERTS, M-DEPLOY
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   log_line - emits structured operator-facing log lines
#   require_root_or_sudo - ensures privileged execution context
#   prompt_value - collects non-empty user input
#   install_docker_stack - installs Docker Engine and Compose plugin when absent
#   generate_proxy_secret - returns a 32-char hex secret
#   generate_proxy_secret_salt - returns a private 32-char hex salt for per-SNI secret derivation
#   prompt_choice - collects a validated install mode choice
#   write_env_file - materializes .env from deploy/.env.example
#   run_cert_bootstrap - invokes wildcard-aware TLS provisioning
#   import_existing_certificates - copies a ready certificate pair into the runtime TLS layout
#   run_compose_up - starts the stack through Docker Compose
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.5.0 - Generate and persist a dedicated per-SNI secret salt alongside the base MTProto secret.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_TEMPLATE="${ROOT_DIR}/deploy/.env.example"
ENV_FILE="${ROOT_DIR}/.env"
CERT_SCRIPT="${ROOT_DIR}/ops/certs/provision-certs.sh"

log_line() {
  local block="$1"
  shift
  printf '[M-INSTALL][run][%s] %s\n' "${block}" "$*"
}

fail() {
  log_line "ERROR" "$*"
  exit 1
}

require_root_or_sudo() {
  if [[ "${EUID}" -ne 0 ]] && ! command -v sudo >/dev/null 2>&1; then
    fail "run as root or install sudo first"
  fi
}

run_privileged() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

prompt_value() {
  local prompt="$1"
  local value=""
  while [[ -z "${value}" ]]; do
    read -r -p "${prompt}: " value
    value="$(printf '%s' "${value}" | xargs)"
  done
  printf '%s' "${value}"
}

prompt_choice() {
  local prompt="$1"
  shift
  local allowed=("$@")
  local value=""
  while true; do
    read -r -p "${prompt} [${allowed[*]}]: " value
    value="$(printf '%s' "${value}" | xargs)"
    for option in "${allowed[@]}"; do
      if [[ "${value}" == "${option}" ]]; then
        printf '%s' "${value}"
        return 0
      fi
    done
  done
}

generate_proxy_secret() {
  openssl rand -hex 16
}

generate_proxy_secret_salt() {
  openssl rand -hex 16
}

ensure_workspace_dirs() {
  mkdir -p "${ROOT_DIR}/volumes/data" "${ROOT_DIR}/volumes/certs" "${ROOT_DIR}/ops/certs"
}

install_docker_stack() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    log_line "DOCKER_BOOTSTRAP" "docker and compose plugin already installed"
    return 0
  fi

  log_line "DOCKER_BOOTSTRAP" "installing docker engine and compose plugin"
  run_privileged apt-get update
  run_privileged apt-get install -y ca-certificates curl gnupg lsb-release
  run_privileged install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | run_privileged gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    run_privileged chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  local arch codename repo
  arch="$(dpkg --print-architecture)"
  codename="$(. /etc/os-release && printf '%s' "${VERSION_CODENAME}")"
  repo="deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable"
  printf '%s\n' "${repo}" | run_privileged tee /etc/apt/sources.list.d/docker.list >/dev/null
  run_privileged apt-get update
  run_privileged apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

write_env_file() {
  local base_domain="$1"
  local resend_api_key="$2"
  local proxy_secret_hex="$3"
  local proxy_secret_salt="$4"
  local certbot_email="admin@${base_domain}"
  local resend_from="KPprotoN <noreply@${base_domain}>"

  [[ -f "${ENV_TEMPLATE}" ]] || fail "missing ${ENV_TEMPLATE}"

  cp "${ENV_TEMPLATE}" "${ENV_FILE}"

  python3 - <<'PY' "${ENV_FILE}" "${base_domain}" "${resend_api_key}" "${proxy_secret_hex}" "${proxy_secret_salt}" "${certbot_email}" "${resend_from}"
import pathlib
import sys

env_path = pathlib.Path(sys.argv[1])
base_domain, resend_api_key, proxy_secret_hex, proxy_secret_salt, certbot_email, resend_from = sys.argv[2:]

replacements = {
    "BASE_DOMAIN": base_domain,
    "PORTAL_URL": f"https://{base_domain}",
    "PROXY_HOST": base_domain,
    "RESEND_API_KEY": resend_api_key,
    "RESEND_FROM": resend_from,
    "PROXY_SECRET_HEX": proxy_secret_hex,
    "PROXY_SECRET_SALT": proxy_secret_salt,
    "TLS_CERT_PATH": f"/certs/live/{base_domain}/fullchain.pem",
    "TLS_KEY_PATH": f"/certs/live/{base_domain}/privkey.pem",
    "TLS_WILDCARD_DOMAIN": f"*.{base_domain}",
    "TLS_CERTBOT_EMAIL": certbot_email,
}

lines = []
for raw_line in env_path.read_text().splitlines():
    if "=" in raw_line and not raw_line.lstrip().startswith("#"):
      key, _ = raw_line.split("=", 1)
      if key in replacements:
        raw_line = f"{key}={replacements[key]}"
    lines.append(raw_line)

env_path.write_text("\n".join(lines) + "\n")
PY
  chmod 600 "${ENV_FILE}"
}

run_cert_bootstrap() {
  local base_domain="$1"
  [[ -f "${CERT_SCRIPT}" ]] || fail "certificate bootstrap script is missing"
  log_line "CERTS_BOOTSTRAP" "starting guided manual wildcard DNS-01 certificate provisioning flow"
  bash "${CERT_SCRIPT}" "${base_domain}" "${ROOT_DIR}/.env"
}

import_existing_certificates() {
  local base_domain="$1"
  local fullchain_path="$2"
  local privkey_path="$3"
  local live_dir="/etc/letsencrypt/live/${base_domain}"
  local cert_subject cert_issuer

  [[ -f "${fullchain_path}" ]] || fail "fullchain certificate file not found: ${fullchain_path}"
  [[ -f "${privkey_path}" ]] || fail "private key file not found: ${privkey_path}"
  [[ -r "${fullchain_path}" ]] || fail "fullchain certificate file is not readable: ${fullchain_path}"
  [[ -r "${privkey_path}" ]] || fail "private key file is not readable: ${privkey_path}"

  openssl x509 -in "${fullchain_path}" -noout >/dev/null 2>&1 || fail "invalid X.509 certificate: ${fullchain_path}"
  openssl pkey -in "${privkey_path}" -noout >/dev/null 2>&1 || fail "invalid private key: ${privkey_path}"

  if ! openssl x509 -in "${fullchain_path}" -noout -text | grep -Eq "DNS:${base_domain}|DNS:\\*\\.${base_domain}"; then
    fail "certificate does not contain ${base_domain} or *.${base_domain} in SAN"
  fi

  cert_subject="$(openssl x509 -in "${fullchain_path}" -noout -subject | sed 's/^subject=//')"
  cert_issuer="$(openssl x509 -in "${fullchain_path}" -noout -issuer | sed 's/^issuer=//')"
  if [[ "${cert_subject}" == "${cert_issuer}" ]]; then
    log_line "CERTS_BOOTSTRAP" "WARNING: imported certificate looks self-signed"
    log_line "CERTS_BOOTSTRAP" "self-signed certificates can expose the web panel but Telegram fake-TLS proxy checks may still report Not Available"
    log_line "CERTS_BOOTSTRAP" "use a publicly trusted wildcard certificate for real MTProto proxy operation"
  fi

  log_line "CERTS_BOOTSTRAP" "importing existing certificate pair into ${live_dir}"
  run_privileged install -d -m 755 "${live_dir}"
  run_privileged install -m 644 "${fullchain_path}" "${live_dir}/fullchain.pem"
  run_privileged install -m 600 "${privkey_path}" "${live_dir}/privkey.pem"
  log_line "CERTS_BOOTSTRAP" "existing certificate material staged for runtime bind mount"
}

run_compose_up() {
  log_line "COMPOSE_UP" "starting docker compose build and launch"
  docker compose --env-file "${ENV_FILE}" up -d --build
}

# START_BLOCK_VALIDATE_INPUT
require_root_or_sudo
command -v openssl >/dev/null 2>&1 || fail "openssl is required"
command -v python3 >/dev/null 2>&1 || fail "python3 is required"

base_domain="${BASE_DOMAIN:-}"
resend_api_key="${RESEND_API_KEY:-}"
tls_mode="${TLS_MODE:-}"
existing_fullchain_path="${EXISTING_CERT_FULLCHAIN_PATH:-}"
existing_privkey_path="${EXISTING_CERT_PRIVKEY_PATH:-}"

if [[ -z "${base_domain}" ]]; then
  base_domain="$(prompt_value 'BASE_DOMAIN')"
fi
if [[ -z "${resend_api_key}" ]]; then
  resend_api_key="$(prompt_value 'RESEND_API_KEY')"
fi
if [[ -z "${tls_mode}" ]]; then
  tls_mode="$(prompt_choice 'TLS_MODE' 'issue-new' 'use-existing')"
fi
if [[ "${tls_mode}" == "use-existing" ]]; then
  if [[ -z "${existing_fullchain_path}" ]]; then
    existing_fullchain_path="$(prompt_value 'EXISTING_CERT_FULLCHAIN_PATH')"
  fi
  if [[ -z "${existing_privkey_path}" ]]; then
    existing_privkey_path="$(prompt_value 'EXISTING_CERT_PRIVKEY_PATH')"
  fi
fi

[[ "${base_domain}" =~ ^[A-Za-z0-9.-]+$ ]] || fail "BASE_DOMAIN contains invalid characters"
[[ "${resend_api_key}" =~ ^re_ ]] || fail "RESEND_API_KEY must look like a Resend key"
[[ "${tls_mode}" == "issue-new" || "${tls_mode}" == "use-existing" ]] || fail "TLS_MODE must be issue-new or use-existing"
log_line "VALIDATE_INPUT" "operator inputs accepted for ${base_domain} with TLS mode ${tls_mode}"
# END_BLOCK_VALIDATE_INPUT

# START_BLOCK_PREPARE_ENV
ensure_workspace_dirs
install_docker_stack
proxy_secret_hex="$(generate_proxy_secret)"
proxy_secret_salt="$(generate_proxy_secret_salt)"
write_env_file "${base_domain}" "${resend_api_key}" "${proxy_secret_hex}" "${proxy_secret_salt}"
log_line "VALIDATE_INPUT" "generated local .env configuration"
# END_BLOCK_PREPARE_ENV

# START_BLOCK_CERTS_BOOTSTRAP
if [[ "${tls_mode}" == "issue-new" ]]; then
  run_cert_bootstrap "${base_domain}"
else
  import_existing_certificates "${base_domain}" "${existing_fullchain_path}" "${existing_privkey_path}"
fi
# END_BLOCK_CERTS_BOOTSTRAP

# START_BLOCK_COMPOSE_UP
run_compose_up
log_line "COMPOSE_UP" "portal url: https://${base_domain}"
# END_BLOCK_COMPOSE_UP
