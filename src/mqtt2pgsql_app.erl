%%%-------------------------------------------------------------------
%% @doc mqtt2pgsql public API
%% @end
%%%-------------------------------------------------------------------

-module(mqtt2pgsql_app).

-behaviour(application).

-include("mqtt2pgsql.hrl").

-emqx_plugin(?MODULE).

-export([ start/2
        , stop/1
        ]).

start(_StartType, _StartArgs) ->
    {ok, Sup} = mqtt2pgsql_sup:start_link(),
    ?APP:load(),
    ?APP:register_metrics(),
    {ok, Sup}.

stop(_State) ->
    ?APP:unload(),
    ok.
