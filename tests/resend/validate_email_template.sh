#!/usr/bin/env bash

# FILE: tests/resend/validate_email_template.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate the shipped email template copy and payload fields for the Resend flow.
#   SCOPE: Static checks for UTF-8 copy, CTA wording, and subject/html/text members.
#   DEPENDS: apps/kpproton_portal/src/integrations/resend/kpproton_email_template.erl
#   LINKS: M-EMAIL-TEMPLATE, V-M-EMAIL-TEMPLATE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   require_pattern - asserts required email-template patterns exist
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added MyGRACE source contract metadata for email-template verification.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/src/integrations/resend/kpproton_email_template.erl"

fail() {
  echo "[M-EMAIL][send_magic_link][BUILD_REQUEST] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

## START_BLOCK_VALIDATE_EMAIL_TEMPLATE
[[ -f "${FILE}" ]] || fail "missing email template"
require_pattern '^%% coding: utf-8$'
require_pattern 'Подтвердите email и получите персональный MTProto-прокси'
require_pattern 'Получить прокси'
require_pattern 'используйте только самую свежую ссылку'
require_pattern 'Если кнопка не работает'
require_pattern 'Если вы не запрашивали прокси'
require_pattern 'text => Text'
require_pattern 'html => Html'
## END_BLOCK_VALIDATE_EMAIL_TEMPLATE

echo "[M-EMAIL][send_magic_link][BUILD_REQUEST] template-ok"
