#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTALL_FILE="${ROOT_DIR}/install.sh"
ENV_FILE="${ROOT_DIR}/deploy/.env.example"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"

fail() {
  echo "[M-INSTALL][run][COMPOSE_UP] $*" >&2
  exit 1
}

[[ -f "${INSTALL_FILE}" ]] || fail "missing install.sh"
[[ -f "${ENV_FILE}" ]] || fail "missing deploy/.env.example"
[[ -f "${COMPOSE_FILE}" ]] || fail "missing docker-compose.yml"

grep -Eq 'run_cert_bootstrap' "${INSTALL_FILE}" || fail "installer does not invoke certificate bootstrap"
grep -Eq 'persist_reg_ru_credentials' "${INSTALL_FILE}" || fail "installer does not persist optional REG.RU credentials"
grep -Eq 'docker compose --env-file' "${INSTALL_FILE}" || fail "installer does not invoke compose with generated env"
grep -Eq '^BASE_DOMAIN=' "${ENV_FILE}" || fail "env template missing BASE_DOMAIN"
grep -Eq '443:443' "${COMPOSE_FILE}" || fail "compose contract missing 443 edge"

echo "[M-INSTALL][run][COMPOSE_UP] readiness-ok"
