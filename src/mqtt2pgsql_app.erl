-module(mqtt2pgsql_app).

-behaviour(application).

-emqx_plugin(?MODULE).

-export([ start/2
        , stop/1
        ]).

start(_StartType, _StartArgs) ->

    {ok, Mqtt2PgsqlConfig} = hocon:load("etc/mqtt2pgsql.hocon"),

    io:format("Mqtt2PgsqlConfig: ~p~n ", [Mqtt2PgsqlConfig]),

    PoolSize = maps:get(<<"poolsize">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("PoolSize: ~p~n", [PoolSize]),

    Host = maps:get(<<"host">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("Host: ~p~n", [Host]),

    Port = maps:get(<<"port">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("Port: ~p~n", [Port]),

    Username = maps:get(<<"username">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("Username: ~p~n", [Username]),

    Password = maps:get(<<"password">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("Password: ~p~n", [Password]),

    Dbname = maps:get(<<"dbname">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("Dbname: ~p~n", [Dbname]),

    SupArgs = [{poolSize, PoolSize},{hostname, Host}, {port, Port}, {username, Username}, {password, Password}, {database,Dbname}],

    SchemaNo = maps:get(<<"schemacount">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("SchemaNo: ~p~n", [SchemaNo]),

    TableNo = maps:get(<<"tablecount">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("TableNo: ~p~n", [TableNo]),

    TablePre = maps:get(<<"tablepre">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("TablePre: ~p~n", [TablePre]),

    TablePost = maps:get(<<"tablepost">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("TablePost: ~p~n", [TablePost]),

    TablePost = maps:get(<<"tablepost">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("TablePost: ~p~n", [TablePost]),

    TablePost = maps:get(<<"tablepost">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("TablePost: ~p~n", [TablePost]),

    ErrorSchema = maps:get(<<"error_schema">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("ErrorSchema: ~p~n", [ErrorSchema]),

    ErrorTable = maps:get(<<"error_table">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("ErrorTable: ~p~n", [ErrorTable]),

    ForceRetainMsg = maps:get(<<"force_retain_msg">>, maps:get(<<"mqtt2pgsql">>, Mqtt2PgsqlConfig)),
    io:format("ForceRetainMsg: ~p~n", [ForceRetainMsg]),


    % Host, Port, Username, Password, Dbname, PidNames, SchemaNo, TableNo, TablePre, TablePost
    {ok, Sup} = mqtt2pgsql_sup:start_link(SupArgs),

    mqtt2pgsql:load(SchemaNo, TableNo, TablePre, TablePost, ErrorSchema, ErrorTable, ForceRetainMsg),

    emqx_ctl:register_command(mqtt2pgsql, {mqtt2pgsql_cli, cmd}),
    {ok, Sup}.

stop(_State) ->
    emqx_ctl:unregister_command(mqtt2pgsql),
    mqtt2pgsql:unload().


print_variable_type(Var) ->
    case Var of
        _ when is_atom(Var) -> io:format("Variable is an atom~n");
        _ when is_binary(Var) -> io:format("Variable is a binary~n");
        _ when is_list(Var) -> io:format("Variable is a list~n");
        _ when is_integer(Var) -> io:format("Variable is an integer~n");
        _ when is_float(Var) -> io:format("Variable is a float~n");
        _ -> io:format("Variable is of unknown type~n")
    end.
