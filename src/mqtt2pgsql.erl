%%--------------------------------------------------------------------
%%  License - :-)
%%--------------------------------------------------------------------

-module(mqtt2pgsql).

-include_lib("emqx/include/emqx.hrl").

-export([load/1, unload/1]).

-export([connect/2, connectPid/1, closeDbConnction/1]). 

-export([on_message_publish/2]).    

-export([cts/1, write/3]).


load(Env) ->
    connectPid(Env),
    emqx:hook('message.publish', {?MODULE, on_message_publish, [Env]}).


on_message_publish(Message = #message{topic =
					  <<"$SYS/", _/binary>>},
		   Env) ->
    {ok, Message};
on_message_publish(Message, Env) ->
    % io:format("Publish ~s~n", [emqx_message:format(Message)]),
    % io:format("Publish ~s~n", [emqx_message:format(Env)]),
    MessageMaps = emqx_message:to_map(Message),
    % io:format("Publish ~p~n", [MessageMaps]),
    % io:format("Publish ~p~n", [emqx_message:to_list(Message)]),
    % io:format("Publish ~p~n", [Env]),


    {ok, PidNames } = application:get_env(mqtt2pgsql, noofcon),

    Topic = string:split(emqx_message:topic(Message), "/",all), 
    
    Payload = emqx_message:payload(Message),
    {ok, SchemaNo} = application:get_env(mqtt2pgsql, schemacount),
    {ok, TableNo} = application:get_env(mqtt2pgsql, tablecount),
    {ok, TablePre} = application:get_env(mqtt2pgsql, tablepre),
    {ok, TablePost} = application:get_env(mqtt2pgsql, tablepost),    
    % Schema = lists:nth(SchemaNo, Topic),
    Table = "\"" ++ binary_to_list(lists:nth(TableNo, Topic)) ++ "\"",
    % Table =  binary_to_list(lists:nth(TableNo, Topic)) ,

    % io:format("Payload is JSON  - ~p~n", [jsx:is_json(Payload)] ),
    % io:format("Payload          - ~p~n", [Payload] ),
    case jsx:is_json(Payload) of 
      true -> 
        case (length(Topic) >= SchemaNo)  and (length(Topic) >= TableNo) of 
          true  -> 
            Ots = maps:merge(
                              maps:put(mqtt2db_ts , os:system_time(), maps:new()) , 
                              maps:put(mqtt_recv_ts , maps:get(timestamp,MessageMaps), maps:new())
                            ),
            PayloadMap  = maps:merge( jsx:decode(Payload, [return_maps]),Ots),
            HeadersBin = maps:keys(PayloadMap),
            Headers = string:join(["" ++ mqtt2pgsql:cts(X) ++ "" || X <- HeadersBin], ","),
            Values = string:join(["'" ++ mqtt2pgsql:cts(X) ++ "'" || X <- lists:map( fun(HeaderBin) -> maps:get(HeaderBin, PayloadMap) end,HeadersBin)], ","), 
            Query = io_lib:format("INSERT INTO  ~s.~s (~s) VALUES(~s) ~n", [mqtt2pgsql:cts(lists:nth(SchemaNo,Topic)), Table, Headers, Values] ),
            % io:format("Query - ~s~n", [Query]),
            lists:nth(rand:uniform(length(PidNames)), PidNames)
            % mqtt2pgsql:write(list_to_atom(lists:flatten(io_lib:format("connection_~p", [rand:uniform(10)]))), Query, Env);
            mqtt2pgsql:write(lists:nth(rand:uniform(length(PidNames)), PidNames), Query, Env);
            
          false ->
            io:format("SchemaNo or TableNo or both worng Topic list - ~p    SchemaNo - ~p   TableNo -  ~p ~n", [Topic, SchemaNo, TableNo] )
        end;
      false -> 
        io:format(" Message is not JSON , Topic - ~p,   Payload - ~p~n" , [emqx_message:topic(Message), Payload])
    end,

    % io:format("Env ~p~n", [Env]),
    % mqtt2pgsql:connect(),
    {ok, Message}.


write(NamePid, Query,Env) ->
  io:format("Name of Connection -  ~p~n", [NamePid]), 
  io:format("Executed Query  -  ~p~n", [Query]), 
    case whereis(NamePid) of 
        undefined ->
            case mqtt2pgsql:connect(NamePid,Env)  of 
                {ok,Pid} ->
                    write(NamePid,Query,Env);
                {Reason} ->
                    {error, Reason}
            end;
        Pid ->
            case epgsql:squery(Pid,Query)  of 
                {error,Reason} ->
                    io:format("epgsql:param_query Error in Writing to DB: ~p~n", [Reason]);
                {ok, Done} ->
                    ok
                    % io:format("odbc:param_query ResultTuple: ~p~n", [ResultTuple])
            end
    end.

connectPid(Env) ->
  io:format("Env ~p~n", [Env]),

  {ok, PidNames } = application:get_env(mqtt2pgsql, noofcon),
  
  lists:map(
    fun(NamePid) ->
      case whereis(NamePid) of 
          undefined ->
            mqtt2pgsql:connect(NamePid,Env)
      end
    end,
    PidNames
  ).

connect(NamePid,Env) ->
  {ok ,Host} = application:get_env(mqtt2pgsql, host), 
  {ok ,Port} = application:get_env(mqtt2pgsql, port),
  {ok ,Username} = application:get_env(mqtt2pgsql, username),
  {ok ,Password} = application:get_env(mqtt2pgsql, password),
  {ok, Dbname} = application:get_env(mqtt2pgsql, dbname),

  case epgsql:connect(Host, Username, Password , #{port => Port , database => Dbname}) of 
    undefined -> io:format("DB Error        -  Ubdefined ~n") ;
    {ok, Pid}->
      try register(NamePid, Pid)
      catch 
        error:X -> 
          io:fwrite(X)   
      end,
      io:fwrite("Connected successfully ~n"),
      {ok, Pid};
    {Error} -> io:format("DB Error          -  ~p~n", [Error]) 
  end.
    

closeDbConnction(Env) ->
  {ok, PidNames } = application:get_env(mqtt2pgsql, noofcon),
  lists:map(
    fun(NamePid) ->
      case whereis(NamePid) of 
          Pid ->
              epgsql:close(NamePid)
      end
    end,
    PidNames
  ).
cts(Value) when is_binary(Value) ->
  binary_to_list(Value);
cts(Value) when is_integer(Value) ->
  integer_to_list(Value);
cts(Value) when is_atom(Value) ->
   io_lib:write_atom(Value);
cts(Value) when is_float(Value) ->
  io_lib:format("~f",[Value]);
cts(Value) ->
  io_lib:format("\"~p\"",[Value]).


%% Called when the plugin application stop
unload(Env) ->
    closeDbConnction(Env),
    emqx:unhook('message.publish',{?MODULE, on_message_publish}).

