#!/usr/bin/env bash

# FILE: tests/mtproto/validate_edge_contract.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that the shared 443 edge routing contract exists and points HTTPS fallback to Cowboy.
#   SCOPE: Static checks for listener port, TLS paths, shared mode, and policy reload hook.
#   DEPENDS: apps/kpproton_proxy/src/mtproto/edge-routing.conf
#   LINKS: M-PROXY-BRIDGE, V-M-PROXY-BRIDGE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required edge-routing configuration exists
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added deterministic validation for shared 443 edge routing.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EDGE_FILE="${ROOT_DIR}/apps/kpproton_proxy/src/mtproto/edge-routing.conf"

fail() {
  echo "[M-PROXY-BRIDGE][edge_routing][ROUTE_443] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${EDGE_FILE}" || fail "missing pattern: ${pattern}"
}

[[ -f "${EDGE_FILE}" ]] || fail "missing edge-routing.conf"
require_pattern '^listener\.port=443$'
require_pattern '^listener\.tls_fullchain=/certs/live/\$\{BASE_DOMAIN\}/fullchain\.pem$'
require_pattern '^routing\.mode=shared-443$'
require_pattern '^routing\.https_fallback=127\.0\.0\.1:8080$'
require_pattern '^routing\.sni_reload_hook=apply_domain_policy$'

echo "[M-PROXY-BRIDGE][edge_routing][ROUTE_443] ok"
