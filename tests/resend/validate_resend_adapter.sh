#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/src/integrations/resend/kpproton_resend_adapter.erl"
TEMPLATE_FILE="${ROOT_DIR}/apps/kpproton_portal/src/integrations/resend/kpproton_email_template.erl"

fail() {
  echo "[M-EMAIL][send_magic_link][BUILD_REQUEST] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

[[ -f "${FILE}" ]] || fail "missing resend adapter"
[[ -f "${TEMPLATE_FILE}" ]] || fail "missing email template"
require_pattern '-export\(\[build_payload/3, map_provider_error/1, send_magic_link/4\]\)'
require_pattern 'https://api\.resend\.com/emails'
require_pattern '\[M-EMAIL\]\[send_magic_link\]\[BUILD_REQUEST\]'
require_pattern 'kpproton_email_template:build_magic_link_email'
require_pattern 'httpc:request'

echo "[M-EMAIL][send_magic_link][BUILD_REQUEST] ok"
