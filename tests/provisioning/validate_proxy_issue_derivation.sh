#!/usr/bin/env bash

# FILE: tests/provisioning/validate_proxy_issue_derivation.sh
# VERSION: 1.0.0
# START_MODULE_CONTRACT
#   PURPOSE: Prove that proxy issuance emits derived per-SNI fake-TLS credentials instead of the raw base secret.
#   SCOPE: Compiled runtime probe for fresh issuance and idempotent reissue behavior.
#   DEPENDS: apps/kpproton_proxy/src/provisioning/kpproton_proxy_issue.erl
#   LINKS: M-PROXY-ISSUE, V-M-PROXY-ISSUE
# END_MODULE_CONTRACT
#
# START_MODULE_MAP
#   fail - emits deterministic provisioning verification failures
# END_MODULE_MAP
#
# START_CHANGE_SUMMARY
#   LAST_CHANGE: v1.0.0 - Added deterministic proof that issued tg links use derived per-SNI credentials and rebuild reused assignments canonically.
# END_CHANGE_SUMMARY

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SECRET_HEX="0123456789abcdef0123456789abcdef"
SECRET_SALT="abcdef0123456789abcdef0123456789"

fail() {
  echo "[M-PROXY-ISSUE][issue_proxy_for_email][BUILD_TG_LINK] $*" >&2
  exit 1
}

cd "${ROOT_DIR}"
rebar3 compile >/dev/null

probe_output="$(
  erl -noshell -pa _build/default/lib/*/ebin -eval '
    application:ensure_all_started(crypto),
    SecretHex = <<"0123456789abcdef0123456789abcdef">>,
    SecretSalt = <<"abcdef0123456789abcdef0123456789">>,
    Email = <<"alice@example.com">>,
    BaseDomain = <<"example.com">>,
    Issued = kpproton_proxy_issue:issue_proxy_for_email(
        Email, BaseDomain, SecretHex, SecretSalt, undefined, 443),
    Sni = maps:get(sni, Issued),
    Link = maps:get(tg_link, Issued),
    RawSecret = mtp_fake_tls:format_secret_hex(SecretHex, Sni),
    DerivedSecret = mtp_fake_tls:format_secret_hex(
        mtp_fake_tls:derive_sni_secret(binary:decode_hex(SecretHex), Sni, SecretSalt),
        Sni),
    ExpectedLink = iolist_to_binary([
        <<"tg://proxy?server=">>, Sni, <<"&port=443&secret=">>, DerivedSecret
    ]),
    Reused = kpproton_proxy_issue:issue_proxy_for_email(
        Email,
        BaseDomain,
        SecretHex,
        SecretSalt,
        #{email => Email, sni => Sni, tg_link => <<"tg://proxy?server=old&port=443&secret=old">>},
        443),
    case {
        maps:get(policy_action, Issued),
        maps:get(policy_action, Reused),
        maps:get(credential_mode, Reused),
        Link =:= ExpectedLink,
        Link =/= iolist_to_binary([<<"tg://proxy?server=">>, Sni, <<"&port=443&secret=">>, RawSecret]),
        maps:get(tg_link, Reused) =:= ExpectedLink
    } of
        {apply_domain_policy, reuse, derived_per_sni, true, true, true} ->
            io:format("DERIVATION_OK");
        Other ->
            io:format("DERIVATION_BAD:~p", [Other]),
            halt(1)
    end,
    halt().'
)"

[[ "${probe_output}" == *"DERIVATION_OK"* ]] || fail "derived per-SNI probe failed: ${probe_output}"

echo "[M-PROXY-ISSUE][issue_proxy_for_email][BUILD_TG_LINK] derivation-ok"
