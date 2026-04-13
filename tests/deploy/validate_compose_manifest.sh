#!/usr/bin/env bash

# FILE: tests/deploy/validate_compose_manifest.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that docker-compose.yml contains the required foundational deployment topology.
#   SCOPE: Presence checks for build target, ports, env file, restart policy, and app service naming.
#   DEPENDS: docker-compose.yml
#   LINKS: M-DEPLOY, V-M-DEPLOY
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts the compose manifest keeps the expected structure
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.1.0 - Parameterized host 443 target port so deployments can route HTTPS directly to Cowboy TLS when shared edge is unavailable.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"

fail() {
  echo "[M-DEPLOY][compose][VALIDATE_MANIFEST] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq "${pattern}" "${COMPOSE_FILE}" || fail "missing pattern: ${pattern}"
}

# START_BLOCK_VALIDATE_MANIFEST
[[ -f "${COMPOSE_FILE}" ]] || fail "missing docker-compose.yml"
require_pattern '^services:$'
require_pattern '^  app:$'
require_pattern '^      target: runtime$'
require_pattern '^    restart: unless-stopped$'
require_pattern '^      - \.env$'
require_pattern '^      - "443:\$\{HOST_HTTPS_TARGET_PORT:-443\}"$'
# END_BLOCK_VALIDATE_MANIFEST

echo "[M-DEPLOY][compose][VALIDATE_MANIFEST] ok"
