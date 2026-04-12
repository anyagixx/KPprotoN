-module(kpproton_core_api).

%% FILE: src/kpproton_core_api.erl
%% VERSION: 1.0.0
%% START_MODULE_CONTRACT
%%   PURPOSE: Fetch Telegram core bootstrap artifacts through the system curl binary for mtproto_proxy startup.
%%   SCOPE: Retrieve getProxySecret/getProxyConfig payloads and normalize failures for local bootstrap handlers.
%%   DEPENDS: M-CONFIG
%%   LINKS: M-PROXY-BRIDGE, M-RELEASE
%% END_MODULE_CONTRACT
%%
%% START_MODULE_MAP
%%   proxy_secret/0 - returns the getProxySecret payload as binary
%%   proxy_config/0 - returns the getProxyConfig payload as binary
%% END_MODULE_MAP
%%
%% START_CHANGE_SUMMARY
%%   LAST_CHANGE: v1.0.0 - Added curl-backed Telegram core bootstrap fetcher for mtproto_proxy startup.
%% END_CHANGE_SUMMARY

-export([proxy_secret/0, proxy_config/0]).

%% START_BLOCK_FETCH_CORE_API
proxy_secret() ->
    fetch_url(os:getenv("PROXY_SECRET_URL", "https://core.telegram.org/getProxySecret")).

proxy_config() ->
    fetch_url(os:getenv("PROXY_CONFIG_URL", "https://core.telegram.org/getProxyConfig")).

fetch_url(Url) ->
    Port = open_port(
        {spawn_executable, "/usr/bin/curl"},
        [
            binary,
            exit_status,
            use_stdio,
            stderr_to_stdout,
            {args, ["-fsSL", "--max-time", "20", Url]}
        ]
    ),
    collect_output(Port, <<>>).

collect_output(Port, Acc) ->
    receive
        {Port, {data, Data}} ->
            collect_output(Port, <<Acc/binary, Data/binary>>);
        {Port, {exit_status, 0}} ->
            {ok, Acc};
        {Port, {exit_status, Status}} ->
            {error, {curl_failed, Status, Acc}}
    after 25000 ->
        port_close(Port),
        {error, timeout}
    end.
%% END_BLOCK_FETCH_CORE_API
