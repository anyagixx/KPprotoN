#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() {
  echo "[M-RELEASE][build][FETCH_DEPS] $*" >&2
  exit 1
}

[[ -f "${ROOT_DIR}/rebar.config" ]] || fail "missing rebar.config"
[[ -f "${ROOT_DIR}/src/kpproton.app.src" ]] || fail "missing application descriptor"
[[ -f "${ROOT_DIR}/src/kpproton_app.erl" ]] || fail "missing OTP app module"
[[ -f "${ROOT_DIR}/src/kpproton_web.erl" ]] || fail "missing web runtime module"
[[ -f "${ROOT_DIR}/tests/release/validate_utf8_runtime_copy.sh" ]] || fail "missing UTF-8 runtime validation"

grep -Eq -- 'cowboy' "${ROOT_DIR}/rebar.config" || fail "cowboy dependency missing"
grep -Eq -- 'jsx' "${ROOT_DIR}/rebar.config" || fail "jsx dependency missing"

echo "[M-RELEASE][build][FETCH_DEPS] rebar-project-ok"
