-module(kpproton_proxy_bridge).

%% FILE: apps/kpproton_proxy/src/mtproto/kpproton_proxy_bridge.erl
%% VERSION: 1.0.0
%% START_MODULE_CONTRACT
%%   PURPOSE: Provide the runtime bridge contract that applies a newly issued SNI policy into the MTProto edge layer.
%%   SCOPE: Observable policy apply hook used by verification and issuance paths.
%%   DEPENDS: M-CONFIG
%%   LINKS: M-PROXY-BRIDGE, M-PROXY-ISSUE
%% END_MODULE_CONTRACT
%%
%% START_MODULE_MAP
%%   apply_domain_policy/1 - loads the issued SNI into mtproto_proxy policy state
%% END_MODULE_MAP
%%
%% START_CHANGE_SUMMARY
%%   LAST_CHANGE: v1.1.0 - Replaced log-only bridge with live mtp_policy_table integration.
%% END_CHANGE_SUMMARY

-export([apply_domain_policy/1]).

%% START_BLOCK_APPLY_POLICY
apply_domain_policy(SniDomain) ->
    io:format("[M-PROXY-BRIDGE][apply_domain_policy][LOAD_POLICY]~n", []),
    case whereis(mtp_policy_table) of
        undefined ->
            {error, mtproto_policy_table_unavailable};
        _Pid ->
            ok = mtp_policy_table:add(personal_domains, tls_domain, SniDomain),
            io:format("[M-PROXY-BRIDGE][apply_domain_policy][APPLY_POLICY] ~ts~n", [SniDomain]),
            ok
    end.
%% END_BLOCK_APPLY_POLICY
