#!/usr/bin/env bash

# FILE: tests/release/validate_per_sni_runtime_config.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Validate that release-time code reads and injects the private per-SNI secret salt.
#   SCOPE: Static source checks plus a compiled runtime probe for the shared salt getter.
#   DEPENDS: src/kpproton_app.erl, src/kpproton_runtime.erl
#   LINKS: M-RELEASE, M-CONFIG, V-M-RELEASE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   fail - emits deterministic release verification failures
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added per-SNI salt boot path verification for the unified Erlang release.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_FILE="${ROOT_DIR}/src/kpproton_app.erl"
RUNTIME_FILE="${ROOT_DIR}/src/kpproton_runtime.erl"
EXPECTED_SALT="phase7-private-salt"

fail() {
  echo "[M-RELEASE][boot][START_RUNTIME] $*" >&2
  exit 1
}

[[ -f "${APP_FILE}" ]] || fail "missing src/kpproton_app.erl"
[[ -f "${RUNTIME_FILE}" ]] || fail "missing src/kpproton_runtime.erl"

grep -Fq 'proxy_secret_salt/0' "${RUNTIME_FILE}" || fail "runtime getter for proxy secret salt is missing"
grep -Fq 'required_env_binary("PROXY_SECRET_SALT")' "${RUNTIME_FILE}" || fail "runtime getter does not require PROXY_SECRET_SALT"
grep -Fq 'kpproton_runtime:proxy_secret_salt()' "${APP_FILE}" || fail "app boot does not read runtime salt"
grep -Fq 'application:set_env(mtproto_proxy, per_sni_secret_salt, SecretSalt)' "${APP_FILE}" || fail "app boot does not inject per_sni_secret_salt"

cd "${ROOT_DIR}"
rebar3 compile >/dev/null

probe_output="$(
  PROXY_SECRET_SALT="${EXPECTED_SALT}" erl -noshell -pa _build/default/lib/*/ebin \
    -eval 'io:format("~s", [kpproton_runtime:proxy_secret_salt()]), halt().'
)"

[[ "${probe_output}" == "${EXPECTED_SALT}" ]] || fail "runtime getter returned unexpected salt"

echo "[M-RELEASE][boot][START_RUNTIME] per-sni-salt-ok"
