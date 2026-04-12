-module(kpproton_verify_handler).
-behaviour(cowboy_handler).

%% FILE: apps/kpproton_portal/src/http/kpproton_verify_handler.erl
%% VERSION: 1.1.0
%% START_MODULE_CONTRACT
%%   PURPOSE: Render the verification-side HTML response contract for consumed tokens and issued proxy links.
%%   SCOPE: Invalid token handling, consumed-token success rendering, and operator-safe error HTML mapping.
%%   DEPENDS: M-TOKEN, M-PROXY-ISSUE
%%   LINKS: M-WEB-API
%% END_MODULE_CONTRACT
%%
%% START_MODULE_MAP
%%   render_verify_result/1 - maps verification outcomes to HTML result pages
%% END_MODULE_MAP
%%
%% START_CHANGE_SUMMARY
%%   LAST_CHANGE: v1.2.0 - Fixed Cowboy query parsing so /verify consumes token instead of crashing with badmatch.
%% END_CHANGE_SUMMARY

-export([init/2, render_verify_result/1]).

init(Req0, State) ->
    QsVals = cowboy_req:parse_qs(Req0),
    Token = proplists:get_value(<<"token">>, QsVals, undefined),
    Html =
        case Token of
            undefined ->
                render_verify_result(undefined);
            _ ->
                case kpproton_runtime:consume_token(Token) of
                    {ok, #{email := Email}} ->
                        Path = kpproton_runtime:registry_path(),
                        {ok, RegistryHandle} = kpproton_registry:open_registry(Path),
                        Existing = kpproton_registry:lookup_user(Email, RegistryHandle),
                        Assignment = kpproton_proxy_issue:issue_proxy_for_email(
                            Email,
                            kpproton_runtime:base_domain(),
                            kpproton_runtime:proxy_secret(),
                            Existing,
                            kpproton_runtime:proxy_port()
                        ),
                        Result =
                            case kpproton_proxy_bridge:apply_domain_policy(maps:get(sni, Assignment)) of
                                ok ->
                                    ok = kpproton_registry:save_user(Email, Assignment, RegistryHandle),
                                    render_verify_result(Assignment);
                                {error, bridge_reason} ->
                                    render_verify_result({error, bridge_reason});
                                {error, Reason} ->
                                    render_verify_result({error, Reason})
                            end,
                        ok = kpproton_registry:close_registry(RegistryHandle),
                        Result;
                    {error, expired} ->
                        render_verify_result({error, expired});
                    _ ->
                        render_verify_result(undefined)
                end
        end,
    Req = cowboy_req:reply(200, #{<<"content-type">> => <<"text/html; charset=utf-8">>}, Html, Req0),
    {ok, Req, State}.

%% START_BLOCK_RENDER_RESULT
render_verify_result(undefined) ->
    io:format("[M-WEB-API][verify_token][RENDER_RESULT]~n", []),
    <<"<html><body><h1>Ссылка недействительна</h1></body></html>">>;
render_verify_result({error, expired}) ->
    io:format("[M-WEB-API][verify_token][RENDER_RESULT]~n", []),
    <<"<html><body><h1>Срок действия ссылки истёк</h1></body></html>">>;
render_verify_result(#{email := Email, tg_link := TgLink, sni := SniDomain}) ->
    io:format("[M-WEB-API][verify_token][CONSUME_TOKEN]~n", []),
    io:format("[M-WEB-API][verify_token][RENDER_RESULT]~n", []),
    iolist_to_binary([
        <<"<html><body><h1>Прокси готов</h1><p>Email: ">>,
        Email,
        <<"</p><p>SNI: ">>,
        SniDomain,
        <<"</p><p><a href=\"">>,
        TgLink,
        <<"\">Открыть tg://proxy</a></p></body></html>">>
    ]);
render_verify_result({error, mtproto_policy_table_unavailable}) ->
    io:format("[M-WEB-API][verify_token][RENDER_RESULT]~n", []),
    <<"<html><body><h1>Прокси-движок недоступен</h1></body></html>">>;
render_verify_result(_) ->
    io:format("[M-WEB-API][verify_token][RENDER_RESULT]~n", []),
    <<"<html><body><h1>Ошибка верификации</h1></body></html>">>.
%% END_BLOCK_RENDER_RESULT
