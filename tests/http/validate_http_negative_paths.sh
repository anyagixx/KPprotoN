#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REQ_FILE="${ROOT_DIR}/apps/kpproton_portal/src/http/kpproton_request_handler.erl"
VERIFY_FILE="${ROOT_DIR}/apps/kpproton_portal/src/http/kpproton_verify_handler.erl"

fail() {
  echo "[M-WEB-API][verify_token][RENDER_RESULT] $*" >&2
  exit 1
}

grep -Eq -- 'invalid_email' "${REQ_FILE}" || fail "missing invalid email path"
grep -Eq -- 'Ссылка недействительна' "${VERIFY_FILE}" || fail "missing invalid token path"
grep -Eq -- 'Срок действия ссылки истёк' "${VERIFY_FILE}" || fail "missing expired token path"
grep -Eq -- 'Ошибка верификации' "${VERIFY_FILE}" || fail "missing generic verification error path"

echo "[M-WEB-API][verify_token][RENDER_RESULT] negative-paths-ok"
