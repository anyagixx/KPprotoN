#!/usr/bin/env bash
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

[[ -f "${FILE}" ]] || fail "missing email template"
require_pattern '^%% coding: utf-8$'
require_pattern 'Подтвердите email и получите персональный MTProto-прокси'
require_pattern 'Получить прокси'
require_pattern 'используйте только самую свежую ссылку'
require_pattern 'Если кнопка не работает'
require_pattern 'Если вы не запрашивали прокси'
require_pattern 'text => Text'
require_pattern 'html => Html'

echo "[M-EMAIL][send_magic_link][BUILD_REQUEST] template-ok"
