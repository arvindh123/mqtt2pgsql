-module(mqtt2pgsql_psql_pool_worker).
-behaviour(gen_server).
-behaviour(poolboy_worker).

-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2,
         code_change/3]).

-record(state, {conn}).

start_link(Args) ->
    gen_server:start_link(?MODULE, Args, []).

init(Args) ->
    process_flag(trap_exit, true),
    start_connection_loop(Args).

start_connection_loop(Args) ->
    Hostname = proplists:get_value(hostname, Args),
    Database = proplists:get_value(database, Args),
    Username = proplists:get_value(username, Args),
    Password = proplists:get_value(password, Args),
    Port = proplists:get_value(port, Args),
    io:format("Worker started  ~p ~p ~p ~p ~p ~n", [Hostname,Database,Username,Password,Port]),

    case epgsql:connect(binary_to_list(Hostname), binary_to_list(Username), binary_to_list(Password), [ {port,Port },{database, binary_to_list(Database)} ] ) of
        {ok, Conn} ->
            {ok, #state{conn=Conn}};
        {error, Reason} ->
            io:format("Error connecting to the database: ~p~n", [Reason]),
            timer:sleep(5000),
            start_connection_loop(Args)
    end.



handle_call({squery, Sql}, _From, #state{conn=Conn}=State) ->
    {reply, epgsql:squery(Conn, Sql), State};
handle_call({equery, Stmt, Params}, _From, #state{conn=Conn}=State) ->
    {reply, epgsql:equery(Conn, Stmt, Params), State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, #state{conn=Conn}) ->
    ok = epgsql:close(Conn),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


