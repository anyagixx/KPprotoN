#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/src/integrations/resend/kpproton_resend_adapter.erl"

fail() {
  echo "[M-EMAIL][send_magic_link][MAP_PROVIDER_ERROR] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

[[ -f "${FILE}" ]] || fail "missing resend adapter"
require_pattern '401'
require_pattern 'invalid_api_key'
require_pattern '429'
require_pattern 'rate_limited'
require_pattern 'provider_unavailable'
require_pattern 'timeout'

echo "[M-EMAIL][send_magic_link][MAP_PROVIDER_ERROR] ok"
