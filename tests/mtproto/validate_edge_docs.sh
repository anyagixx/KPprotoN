#!/usr/bin/env bash

# FILE: tests/mtproto/validate_edge_docs.sh
# VERSION: 1.1.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate operator-facing documentation for shared 443 routing, TLS mount behavior, and per-SNI rollout requirements.
#   SCOPE: Static checks for README statements around port 443, Cowboy fallback, policy reload, and forced reissue after secret rotation.
#   DEPENDS: apps/kpproton_proxy/src/mtproto/README.md
#   LINKS: M-PROXY-BRIDGE, V-M-PROXY-BRIDGE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required routing documentation exists
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.1.0 - Added rollout documentation validation for per-SNI secret enforcement and forced link reissue.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
README_FILE="${ROOT_DIR}/apps/kpproton_proxy/src/mtproto/README.md"

fail() {
  echo "[M-PROXY-BRIDGE][apply_domain_policy][LOAD_POLICY] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${README_FILE}" || fail "missing pattern: ${pattern}"
}

[[ -f "${README_FILE}" ]] || fail "missing mtproto README"
require_pattern 'External listener port is `443`'
require_pattern '/certs/live/<BASE_DOMAIN>/fullchain\.pem'
require_pattern 'Cowboy on `127\.0\.0\.1:8080`'
require_pattern 'apply_domain_policy'
require_pattern 'invalidates all previously issued `tg://proxy` links'
require_pattern 'reissued link for the same SNI'

echo "[M-PROXY-BRIDGE][apply_domain_policy][LOAD_POLICY] ok"
