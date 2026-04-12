#!/usr/bin/env bash

# FILE: install.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Bootstrap a clean Ubuntu host into a runnable KPprotoN deployment with minimal operator input.
#   SCOPE: Collect domain and Resend API key, install Docker tooling, generate shared env, prepare storage, invoke cert provisioning, and start compose.
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
#   persist_reg_ru_credentials - stores optional REG.RU API credentials for automated DNS-01 runs
#   write_env_file - materializes .env from deploy/.env.example
#   run_cert_bootstrap - invokes wildcard-aware TLS provisioning
#   run_compose_up - starts the stack through Docker Compose
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.1.0 - Added optional REG.RU credential persistence for automated DNS-01 wildcard issuance without extra prompts.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_TEMPLATE="${ROOT_DIR}/deploy/.env.example"
ENV_FILE="${ROOT_DIR}/.env"
CERT_SCRIPT="${ROOT_DIR}/ops/certs/provision-certs.sh"
REGRU_CREDENTIALS_FILE="/etc/kpproton/reg.ru.credentials"

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

generate_proxy_secret() {
  openssl rand -hex 16
}

ensure_workspace_dirs() {
  mkdir -p "${ROOT_DIR}/volumes/data" "${ROOT_DIR}/volumes/certs" "${ROOT_DIR}/ops/certs"
}

persist_reg_ru_credentials() {
  local username="${REGRU_API_USERNAME:-}"
  local password="${REGRU_API_PASSWORD:-}"

  if [[ -z "${username}" || -z "${password}" ]]; then
    log_line "CERTS_BOOTSTRAP" "REG.RU API credentials not provided, installer will use manual DNS-01 fallback"
    return 0
  fi

  log_line "CERTS_BOOTSTRAP" "persisting REG.RU API credentials for automated DNS-01"
  run_privileged install -d -m 700 /etc/kpproton
  run_privileged tee "${REGRU_CREDENTIALS_FILE}" >/dev/null <<EOF
REGRU_API_USERNAME=${username}
REGRU_API_PASSWORD=${password}
EOF
  run_privileged chmod 600 "${REGRU_CREDENTIALS_FILE}"
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
  local certbot_email="admin@${base_domain}"
  local resend_from="KPprotoN <noreply@${base_domain}>"

  [[ -f "${ENV_TEMPLATE}" ]] || fail "missing ${ENV_TEMPLATE}"

  cp "${ENV_TEMPLATE}" "${ENV_FILE}"

  python3 - <<'PY' "${ENV_FILE}" "${base_domain}" "${resend_api_key}" "${proxy_secret_hex}" "${certbot_email}" "${resend_from}"
import pathlib
import sys

env_path = pathlib.Path(sys.argv[1])
base_domain, resend_api_key, proxy_secret_hex, certbot_email, resend_from = sys.argv[2:]

replacements = {
    "BASE_DOMAIN": base_domain,
    "PORTAL_URL": f"https://{base_domain}",
    "PROXY_HOST": base_domain,
    "RESEND_API_KEY": resend_api_key,
    "RESEND_FROM": resend_from,
    "PROXY_SECRET_HEX": proxy_secret_hex,
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
  [[ -x "${CERT_SCRIPT}" ]] || fail "certificate bootstrap script is missing or not executable"
  log_line "CERTS_BOOTSTRAP" "starting wildcard-aware certificate provisioning flow"
  REGRU_CREDENTIALS_FILE="${REGRU_CREDENTIALS_FILE}" "${CERT_SCRIPT}" "${base_domain}" "${ROOT_DIR}/.env"
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

if [[ -z "${base_domain}" ]]; then
  base_domain="$(prompt_value 'BASE_DOMAIN')"
fi
if [[ -z "${resend_api_key}" ]]; then
  resend_api_key="$(prompt_value 'RESEND_API_KEY')"
fi

[[ "${base_domain}" =~ ^[A-Za-z0-9.-]+$ ]] || fail "BASE_DOMAIN contains invalid characters"
[[ "${resend_api_key}" =~ ^re_ ]] || fail "RESEND_API_KEY must look like a Resend key"
log_line "VALIDATE_INPUT" "operator inputs accepted for ${base_domain}"
# END_BLOCK_VALIDATE_INPUT

# START_BLOCK_PREPARE_ENV
ensure_workspace_dirs
install_docker_stack
proxy_secret_hex="$(generate_proxy_secret)"
persist_reg_ru_credentials
write_env_file "${base_domain}" "${resend_api_key}" "${proxy_secret_hex}"
log_line "VALIDATE_INPUT" "generated local .env configuration"
# END_BLOCK_PREPARE_ENV

# START_BLOCK_CERTS_BOOTSTRAP
run_cert_bootstrap "${base_domain}"
# END_BLOCK_CERTS_BOOTSTRAP

# START_BLOCK_COMPOSE_UP
run_compose_up
log_line "COMPOSE_UP" "portal url: https://${base_domain}"
# END_BLOCK_COMPOSE_UP
