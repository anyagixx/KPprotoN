#!/usr/bin/env bash

# FILE: tests/mtproto/validate_per_sni_secret_enforcement.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Prove that MTProto fake-TLS validation accepts derived per-SNI secrets and rejects the raw base secret once enforcement is enabled.
#   SCOPE: Static runtime-config guard plus a compiled fake-TLS handshake probe using the upstream listener codec.
#   DEPENDS: src/kpproton_app.erl, _build/default/lib/mtproto_proxy/src/mtp_fake_tls.erl
#   LINKS: M-PROXY-BRIDGE, M-RELEASE, V-M-PROXY-BRIDGE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   fail - emits deterministic MTProto enforcement verification failures
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added a local deterministic proof for derived-secret acceptance and raw-secret rejection.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_FILE="${ROOT_DIR}/src/kpproton_app.erl"
MTP_FAKE_TLS_SRC="${ROOT_DIR}/_build/default/lib/mtproto_proxy/src/mtp_fake_tls.erl"
TMP_DIR="$(mktemp -d /tmp/kpproton-mtp-fake-tls-XXXXXX)"
trap 'rm -rf "${TMP_DIR}"' EXIT

fail() {
  echo "[M-PROXY-BRIDGE][apply_domain_policy][APPLY_POLICY] $*" >&2
  exit 1
}

[[ -f "${APP_FILE}" ]] || fail "missing src/kpproton_app.erl"
[[ -f "${MTP_FAKE_TLS_SRC}" ]] || fail "missing mtp_fake_tls source"
grep -Fq 'application:set_env(mtproto_proxy, per_sni_secrets, on)' "${APP_FILE}" || fail "per_sni_secrets is not enabled in app boot"

cd "${ROOT_DIR}"
rebar3 compile >/dev/null
erlc -DTEST -o "${TMP_DIR}" "${MTP_FAKE_TLS_SRC}" >/dev/null

probe_output="$(
  MTP_FAKE_TLS_TMPDIR="${TMP_DIR}" erl -noshell -pa _build/default/lib/*/ebin -eval '
    code:purge(mtp_fake_tls),
    code:delete(mtp_fake_tls),
    {module, mtp_fake_tls} = code:load_abs(filename:join(os:getenv("MTP_FAKE_TLS_TMPDIR"), "mtp_fake_tls")),
    application:ensure_all_started(crypto),
    RawSecretHex = <<"0123456789abcdef0123456789abcdef">>,
    RawSecret = binary:decode_hex(RawSecretHex),
    Salt = <<"abcdef0123456789abcdef0123456789">>,
    Domain = <<"alice.example.com">>,
    DerivedSecret = mtp_fake_tls:derive_sni_secret(RawSecret, Domain, Salt),
    Timestamp = erlang:system_time(second),
    SessionId = crypto:strong_rand_bytes(32),
    DerivedHello = mtp_fake_tls:make_client_hello(Timestamp, SessionId, DerivedSecret, Domain, 517),
    {ok, _Response, Meta, _Codec} = mtp_fake_tls:from_client_hello(DerivedHello, DerivedSecret),
    RawHello = mtp_fake_tls:make_client_hello(Timestamp, SessionId, RawSecret, Domain, 517),
    RawRejected =
        try
            mtp_fake_tls:from_client_hello(RawHello, DerivedSecret),
            false
        catch
            error:{protocol_error, tls_invalid_digest, _} ->
                true
        end,
    case {maps:get(sni_domain, Meta), RawRejected} of
        {Domain, true} ->
            io:format("PER_SNI_ENFORCEMENT_OK");
        Other ->
            io:format("PER_SNI_ENFORCEMENT_BAD:~p", [Other]),
            halt(1)
    end,
    halt().'
)"

[[ "${probe_output}" == *"PER_SNI_ENFORCEMENT_OK"* ]] || fail "per-SNI enforcement probe failed: ${probe_output}"

echo "[M-PROXY-BRIDGE][apply_domain_policy][APPLY_POLICY] per-sni-enforcement-ok"
