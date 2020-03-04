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
    mqtt2pgsql:load(application:get_all_env()),
    {ok, Db} = application:get_env(mqtt2pgsql, db),
    io:format("Database Host ~p~n ", [Db]),
    % {ok, MqttParam} = application:get_env(mqtt2pgsql, mqtt),
    % io:format("Database Host ~p~n ", [MqttParam]),
    {ok, Sup}.

stop(_State) ->
    mqtt2pgsql:unload(application:get_all_env()).