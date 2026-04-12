#!/usr/bin/env bash

# FILE: tests/deploy/validate_volume_contract.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that docker-compose.yml preserves the persistent mount contract for KPprotoN runtime state.
#   SCOPE: Checks data and certificate volume targets and shared 443 edge mode presence.
#   DEPENDS: docker-compose.yml
#   LINKS: M-DEPLOY, V-M-DEPLOY
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts that a required mount or env line is present
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added deterministic volume contract validation.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"

fail() {
  echo "[M-DEPLOY][compose][START_STACK] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq "${pattern}" "${COMPOSE_FILE}" || fail "missing pattern: ${pattern}"
}

# START_BLOCK_VALIDATE_VOLUMES
[[ -f "${COMPOSE_FILE}" ]] || fail "missing docker-compose.yml"
require_pattern 'KP_EDGE_MODE: shared-443'
require_pattern '/var/lib/kpproton'
require_pattern ':/certs:ro'
require_pattern 'command: \["foundation-ready"\]'
# END_BLOCK_VALIDATE_VOLUMES

echo "[M-DEPLOY][compose][START_STACK] ok"
