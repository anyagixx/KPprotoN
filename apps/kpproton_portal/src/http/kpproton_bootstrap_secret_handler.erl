-module(kpproton_bootstrap_secret_handler).
-behaviour(cowboy_handler).

-export([init/2]).

init(Req0, State) ->
    {Status, Body} =
        case kpproton_core_api:proxy_secret() of
            {ok, Secret} -> {200, Secret};
            {error, _} -> {502, <<"bootstrap secret unavailable">>}
        end,
    Req = cowboy_req:reply(Status, #{<<"content-type">> => <<"text/plain; charset=utf-8">>}, Body, Req0),
    {ok, Req, State}.
