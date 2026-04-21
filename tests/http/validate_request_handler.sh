#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/src/http/kpproton_request_handler.erl"

fail() {
  echo "[M-WEB-API][request_email][VALIDATE_INPUT] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

[[ -f "${FILE}" ]] || fail "missing request handler"
require_pattern '^%% coding: utf-8$'
require_pattern '-export\(\[init/2, validate_email/1, handle_request/1, health_response/0\]\)'
require_pattern 'invalid_email'
require_pattern '\[M-WEB-API\]\[request_email\]\[VALIDATE_INPUT\]'
require_pattern '\[M-WEB-API\]\[request_email\]\[DISPATCH_EMAIL\]'
require_pattern 'Проверьте почту'
require_pattern 'jsx:decode'

echo "[M-WEB-API][request_email][VALIDATE_INPUT] ok"
