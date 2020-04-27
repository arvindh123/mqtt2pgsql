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

    {ok, Db} = application:get_env(mqtt2pgsql, db),
    io:format("Database Host ~p~n ", [Db]),

    {ok, PidNames } = application:get_env(mqtt2pgsql, noofcon),

    {ok, SchemaNo} = application:get_env(mqtt2pgsql, schemacount),
    {ok, TableNo} = application:get_env(mqtt2pgsql, tablecount),
    {ok, TablePre} = application:get_env(mqtt2pgsql, tablepre),
    {ok, TablePost} = application:get_env(mqtt2pgsql, tablepost),    

    {ok ,Host} = application:get_env(mqtt2pgsql, host), 
    {ok ,Port} = application:get_env(mqtt2pgsql, port),
    {ok ,Username} = application:get_env(mqtt2pgsql, username),
    {ok ,Password} = application:get_env(mqtt2pgsql, password),
    {ok, Dbname} = application:get_env(mqtt2pgsql, dbname),

    % Host, Port, Username, Password, Dbname, PidNames, SchemaNo, TableNo, TablePre, TablePost
    {ok, Sup} = mqtt2pgsql_sup:start_link(),

    mqtt2pgsql:load(Host, Port, Username, Password, Dbname, PidNames, SchemaNo, TableNo, TablePre, TablePost),

    % {ok, MqttParam} = application:get_env(mqtt2pgsql, mqtt),
    % io:format("Database Host ~p~n ", [MqttParam]),
    {ok, Sup}.

stop(_State) ->
    {ok, PidNames } = application:get_env(mqtt2pgsql, noofcon),
    mqtt2pgsql:unload(PidNames).