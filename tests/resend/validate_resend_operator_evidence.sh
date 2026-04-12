#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/src/integrations/resend/kpproton_resend_adapter.erl"

fail() {
  echo "[M-EMAIL][send_magic_link][MAP_PROVIDER_ERROR] $*" >&2
  exit 1
}

grep -Eq -- '\{error, invalid_api_key\}' "${FILE}" || fail "missing 401 mapping"
grep -Eq -- '\{error, rate_limited\}' "${FILE}" || fail "missing 429 mapping"
grep -Eq -- '\{error, provider_unavailable\}' "${FILE}" || fail "missing 5xx mapping"
grep -Eq -- '\{error, timeout\}' "${FILE}" || fail "missing timeout mapping"

echo "[M-EMAIL][send_magic_link][MAP_PROVIDER_ERROR] operator-evidence-ok"
