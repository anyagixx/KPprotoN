#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/apps/kpproton_portal/priv/static/request.js"

fail() {
  echo "[M-WEB-UI][submit][REQUEST_PROXY] $*" >&2
  exit 1
}

require_pattern() {
  local pattern="$1"
  grep -Eq -- "${pattern}" "${FILE}" || fail "missing pattern: ${pattern}"
}

[[ -f "${FILE}" ]] || fail "missing request.js"
require_pattern 'fetch\("/api/request"'
require_pattern '\[M-WEB-UI\]\[submit\]\[REQUEST_PROXY\]'
require_pattern '\[M-WEB-UI\]\[state\]\[SHOW_CHECK_EMAIL\]'
require_pattern '\[M-WEB-UI\]\[state\]\[SHOW_ERROR\]'
require_pattern 'setStatus\("success"'

echo "[M-WEB-UI][submit][REQUEST_PROXY] ok"
