#!/usr/bin/env bash

# FILE: tests/install/validate_install_contract.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that install.sh preserves the required operator flow and integration hooks.
#   SCOPE: Static pattern checks for prompts, Docker bootstrap, env generation, cert call, and compose launch.
#   DEPENDS: install.sh
#   LINKS: M-INSTALL, V-M-INSTALL
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts a required install contract pattern exists
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.2.0 - Removed REG.RU automation expectations and kept manual wildcard issuance plus existing certificate import.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTALL_FILE="${ROOT_DIR}/install.sh"

fail() {
  echo "[M-INSTALL][run][VALIDATE_INPUT] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq "${pattern}" "${INSTALL_FILE}" || fail "missing pattern: ${pattern}"
}

[[ -f "${INSTALL_FILE}" ]] || fail "missing install.sh"
require_pattern 'prompt_value '\''BASE_DOMAIN'\'''
require_pattern 'prompt_value '\''RESEND_API_KEY'\'''
require_pattern 'prompt_choice '\''TLS_MODE'\'''
require_pattern 'generate_proxy_secret'
require_pattern 'install_docker_stack'
require_pattern 'run_cert_bootstrap'
require_pattern 'import_existing_certificates'
require_pattern 'EXISTING_CERT_FULLCHAIN_PATH'
require_pattern 'EXISTING_CERT_PRIVKEY_PATH'
require_pattern 'docker compose --env-file'

echo "[M-INSTALL][run][VALIDATE_INPUT] ok"
