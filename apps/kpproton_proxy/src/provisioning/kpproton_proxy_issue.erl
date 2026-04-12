-module(kpproton_proxy_issue).

%% FILE: apps/kpproton_proxy/src/provisioning/kpproton_proxy_issue.erl
%% VERSION: 1.1.0
%% START_MODULE_CONTRACT
%%   PURPOSE: Define the issuance contract that turns a verified email into a stable SNI domain and tg://proxy link.
%%   SCOPE: Deterministic SNI generation, idempotent assignment reuse, proxy link assembly, and policy action contract output.
%%   DEPENDS: M-REGISTRY, M-PROXY-BRIDGE
%%   LINKS: M-PROXY-ISSUE, M-WEB-API
%% END_MODULE_CONTRACT
%%
%% START_MODULE_MAP
%%   generate_sni/2 - creates a hex-prefixed subdomain for a verified email
%%   build_tg_link/4 - assembles the tg://proxy link
%%   issue_proxy_for_email/5 - returns idempotent assignment metadata and policy action info
%% END_MODULE_MAP
%%
%% START_CHANGE_SUMMARY
%%   LAST_CHANGE: v1.2.0 - Switched tg://proxy secret assembly to upstream fake-TLS format and rebuild reused assignments with the canonical link.
%% END_CHANGE_SUMMARY

-export([generate_sni/2, build_tg_link/4, issue_proxy_for_email/5]).

%% START_BLOCK_GENERATE_SNI
generate_sni(Email, BaseDomain) ->
    io:format("[M-PROXY-ISSUE][issue_proxy_for_email][GENERATE_SNI]~n", []),
    HashHex = binary:encode_hex(crypto:hash(sha256, Email)),
    Prefix = binary:part(HashHex, 0, 12),
    <<Prefix/binary, ".", BaseDomain/binary>>.
%% END_BLOCK_GENERATE_SNI

%% START_BLOCK_BUILD_TG_LINK
build_tg_link(Host, SecretHex, Port, SniDomain) ->
    io:format("[M-PROXY-ISSUE][issue_proxy_for_email][BUILD_TG_LINK]~n", []),
    FakeTlsSecret = mtp_fake_tls:format_secret_hex(SecretHex, SniDomain),
    iolist_to_binary([
        <<"tg://proxy?server=">>, Host,
        <<"&port=">>, integer_to_binary(Port),
        <<"&secret=">>, FakeTlsSecret
    ]).
%% END_BLOCK_BUILD_TG_LINK

%% START_BLOCK_PERSIST_ASSIGNMENT
issue_proxy_for_email(Email, BaseDomain, SecretHex, ExistingAssignment, Port) ->
    case ExistingAssignment of
        #{sni := ExistingSni} = Assignment ->
            io:format("[M-PROXY-ISSUE][issue_proxy_for_email][PERSIST_ASSIGNMENT]~n", []),
            Assignment#{
                tg_link => build_tg_link(ExistingSni, SecretHex, Port, ExistingSni),
                policy_action => reuse
            };
        undefined ->
            SniDomain = generate_sni(Email, BaseDomain),
            TgLink = build_tg_link(SniDomain, SecretHex, Port, SniDomain),
            io:format("[M-PROXY-ISSUE][issue_proxy_for_email][PERSIST_ASSIGNMENT]~n", []),
            #{
                email => Email,
                sni => SniDomain,
                tg_link => TgLink,
                policy_action => apply_domain_policy
            }
    end.
%% END_BLOCK_PERSIST_ASSIGNMENT
