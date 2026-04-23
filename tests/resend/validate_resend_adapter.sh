#!/usr/bin/env bash

# FILE: tests/resend/validate_resend_adapter.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate the Resend adapter request-building path and template integration.
#   SCOPE: Static checks for exports, provider endpoint, log marker, template builder usage, and HTTP client call.
#   DEPENDS: apps/kpproton_portal/src/integrations/resend/kpproton_resend_adapter.erl, apps/kpproton_portal/src/integrations/resend/kpproton_email_template.erl
#   LINKS: M-EMAIL, V-M-EMAIL
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required Resend adapter patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for Resend adapter verification.
# END_CHANGE_SUMMARY

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

## START_BLOCK_VALIDATE_RESEND_ADAPTER
[[ -f "${FILE}" ]] || fail "missing resend adapter"
[[ -f "${TEMPLATE_FILE}" ]] || fail "missing email template"
require_pattern '-export\(\[build_payload/3, map_provider_error/1, send_magic_link/4\]\)'
require_pattern 'https://api\.resend\.com/emails'
require_pattern '\[M-EMAIL\]\[send_magic_link\]\[BUILD_REQUEST\]'
require_pattern 'kpproton_email_template:build_magic_link_email'
require_pattern 'httpc:request'
## END_BLOCK_VALIDATE_RESEND_ADAPTER

echo "[M-EMAIL][send_magic_link][BUILD_REQUEST] ok"
