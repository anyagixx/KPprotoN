#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${ROOT_DIR}/scripts/build_release.sh"

fail() {
  echo "[M-RELEASE][build][ASSEMBLE_RELEASE] $*" >&2
  exit 1
}

[[ -f "${FILE}" ]] || fail "missing scripts/build_release.sh"

grep -Eq -- '/tmp/kpproton_release_ascii' "${FILE}" || fail "missing ASCII stage directory"
grep -Eq -- 'rebar3 as prod release' "${FILE}" || fail "missing relx invocation"
grep -Eq -- 'cp -a "\$\{STAGE_DIR\}/_build/prod/rel/kpproton"' "${FILE}" || fail "missing sync-back step"

echo "[M-RELEASE][build][ASSEMBLE_RELEASE] wrapper-ok"
