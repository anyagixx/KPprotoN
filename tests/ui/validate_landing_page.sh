#!/usr/bin/env bash

# FILE: tests/ui/validate_landing_page.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate the landing page structure for email submission UI.
#   SCOPE: Static checks for form markup, email input, CTA, status area, and linked request script.
#   DEPENDS: apps/kpproton_portal/priv/static/index.html
#   LINKS: M-WEB-UI, V-M-WEB-UI
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required landing-page patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for landing-page verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/priv/static/index.html"

fail() {
  echo "[M-WEB-UI][state][SHOW_ERROR] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

## START_BLOCK_VALIDATE_LANDING_PAGE
[[ -f "${FILE}" ]] || fail "missing index.html"
require_pattern '<form id="request-form"'
require_pattern 'type="email"'
require_pattern 'Получить прокси'
require_pattern 'id="request-status"'
require_pattern '/static/request.js'
## END_BLOCK_VALIDATE_LANDING_PAGE

echo "[M-WEB-UI][state][SHOW_CHECK_EMAIL] ok"
