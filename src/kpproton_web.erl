-module(kpproton_web).
-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/", cowboy_static, {file, filename:join(kpproton_runtime:static_root(), "index.html")}},
            {"/static/[...]", cowboy_static, {dir, kpproton_runtime:static_root()}},
            {"/bootstrap/proxy-secret", kpproton_bootstrap_secret_handler, #{}},
            {"/bootstrap/proxy-config", kpproton_bootstrap_config_handler, #{}},
            {"/api/request", kpproton_request_handler, #{}},
            {"/verify", kpproton_verify_handler, #{}},
            {"/health", kpproton_health_handler, #{}}
        ]}
    ]),
    {ok, _} = cowboy:start_clear(
        kpproton_http,
        [{port, kpproton_runtime:portal_port()}],
        #{env => #{dispatch => Dispatch}}
    ),
    {ok, _} = cowboy:start_tls(
        kpproton_https,
        [
            {port, kpproton_runtime:portal_tls_port()},
            {certfile, kpproton_runtime:tls_cert_path()},
            {keyfile, kpproton_runtime:tls_key_path()}
        ],
        #{env => #{dispatch => Dispatch}}
    ),
    {ok, #{}}.

handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok = cowboy:stop_listener(kpproton_http),
    ok = cowboy:stop_listener(kpproton_https),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
