-module(kpproton_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    RuntimeChild = #{
        id => kpproton_runtime,
        start => {kpproton_runtime, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [kpproton_runtime]
    },
    WebChild = #{
        id => kpproton_web,
        start => {kpproton_web, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [kpproton_web]
    },
    MtprotoBootChild = #{
        id => kpproton_mtproto_boot,
        start => {kpproton_mtproto_boot, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [kpproton_mtproto_boot]
    },
    {ok, {{one_for_one, 5, 10}, [RuntimeChild, WebChild, MtprotoBootChild]}}.
