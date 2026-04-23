#!/usr/bin/env bash

# FILE: tests/install/validate_install_readiness.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that installer prerequisites for compose startup remain aligned with env and edge contracts.
#   SCOPE: Static checks for install.sh wiring, env template keys, and compose 443 publish behavior.
#   DEPENDS: install.sh, deploy/.env.example, docker-compose.yml
#   LINKS: M-INSTALL, V-M-INSTALL
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   none - performs direct readiness checks against installer-facing files
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for installer readiness verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTALL_FILE="${ROOT_DIR}/install.sh"
ENV_FILE="${ROOT_DIR}/deploy/.env.example"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"

fail() {
  echo "[M-INSTALL][run][COMPOSE_UP] $*" >&2
  exit 1
}

## START_BLOCK_VALIDATE_INSTALL_READINESS
[[ -f "${INSTALL_FILE}" ]] || fail "missing install.sh"
[[ -f "${ENV_FILE}" ]] || fail "missing deploy/.env.example"
[[ -f "${COMPOSE_FILE}" ]] || fail "missing docker-compose.yml"

grep -Eq 'run_cert_bootstrap' "${INSTALL_FILE}" || fail "installer does not invoke certificate bootstrap"
grep -Eq 'import_existing_certificates' "${INSTALL_FILE}" || fail "installer does not support existing certificate import"
grep -Eq 'TLS_MODE' "${INSTALL_FILE}" || fail "installer does not branch by TLS mode"
grep -Eq 'docker compose --env-file' "${INSTALL_FILE}" || fail "installer does not invoke compose with generated env"
grep -Eq '^BASE_DOMAIN=' "${ENV_FILE}" || fail "env template missing BASE_DOMAIN"
grep -Eq '^PROXY_SECRET_SALT=' "${ENV_FILE}" || fail "env template missing PROXY_SECRET_SALT"
grep -Eq '443:\$\{HOST_HTTPS_TARGET_PORT:-443\}' "${COMPOSE_FILE}" || fail "compose contract missing configurable 443 edge"
## END_BLOCK_VALIDATE_INSTALL_READINESS

echo "[M-INSTALL][run][COMPOSE_UP] readiness-ok"
