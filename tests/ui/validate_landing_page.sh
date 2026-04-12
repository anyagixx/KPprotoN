#!/usr/bin/env bash
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

[[ -f "${FILE}" ]] || fail "missing index.html"
require_pattern '<form id="request-form"'
require_pattern 'type="email"'
require_pattern 'Получить прокси'
require_pattern 'id="request-status"'
require_pattern '/static/request.js'

echo "[M-WEB-UI][state][SHOW_CHECK_EMAIL] ok"
