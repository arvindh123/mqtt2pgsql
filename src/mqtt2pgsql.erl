-module(mqtt2pgsql).

%% for #message{} record
%% no need for this include if we call emqx_message:to_map/1 to convert it to a map
-include_lib("emqx/include/emqx.hrl").
-include_lib("emqx/include/emqx_hooks.hrl").

%% for logging
-include_lib("emqx/include/logger.hrl").

-export([load/7, unload/0]).

-export([on_message_publish/8]).


load(SchemaNo, TableNo, TablePre, TablePost, ErrorSchema, ErrorTable, ForceRetainMsg) ->
    emqx_hooks:add('message.publish', {?MODULE, on_message_publish, [  SchemaNo, TableNo, TablePre, TablePost, ErrorSchema, ErrorTable, ForceRetainMsg]}, _Property = ?HP_HIGHEST).

%% Called when the plugin application stop
unload() ->
    emqx_hooks:del('message.publish',{?MODULE, on_message_publish}).


on_message_publish(Message = #message{topic = <<"$SYS/", _/binary>>}, _SchemaNo, _TableNo, _TablePre, _TablePost,  _ErrorSchema, _ErrorTable, _ForceRetainMsg) ->
    {ok, Message};

on_message_publish(Message, SchemaNo, TableNo, TablePre, TablePost, ErrorSchema, ErrorTable, ForceRetainMsg) ->
    % io:format("Publish ~s~n", [emqx_message:format(Env)]),
    % io:format("Actual Message ~p~n", [Message]),
    % MessageMaps = emqx_message:to_map(Message),

    % UpdatedMessageMaps = maps:update(flags, #{dup => false, retain => true}, MessageMaps),
    % UpdatedMessage = emqx_message:from_map(UpdatedMessageMaps),

    {message,  MsgId,  QoS,  ClientId,  Flags,  Headers,  Topic,  Payload, Timestamp, Extra} = Message,
    % Create a new map with the retain field updated to true
    UpdatedMessage = {message, MsgId, QoS, ClientId, Flags#{retain => ForceRetainMsg}, Headers, Topic, Payload, Timestamp, Extra},
    % io:format("Updated Message ~p~n", [UpdatedMessage]),

    spawn(fun() ->
      execute_insert_query(Message, SchemaNo, TableNo, TablePre, TablePost, ErrorSchema, ErrorTable)
    end),

    % spawn_link attach the child process to it parent
    % InsertProcess = spawn_link(fun() ->
    %   execute_insert_query(Message, SchemaNo, TableNo, TablePre, TablePost)
    % end),

    {ok, UpdatedMessage}.

execute_insert_query(Msg,SchemaNo, TableNo, TablePre, TablePost, ErrorSchema, ErrorTable) ->
    FullTopic = emqx_message:topic(Msg),
    SplitTopic = string:split(FullTopic, "/",all),
    Payload = emqx_message:payload(Msg),
    MqttTime = emqx_message:timestamp(Msg),
    MqttClientID = emqx_message:from(Msg),
    MqttHeaders = emqx_message:get_headers(Msg),

    case jsx:is_json(Payload) of
      true ->
        case (length(SplitTopic) >= SchemaNo)  and (length(SplitTopic) >= TableNo) of
          true  ->
            Table = cts(TablePre) ++ cts(lists:nth(TableNo, SplitTopic)) ++ cts(TablePost),
            Schema = cts(lists:nth(SchemaNo,SplitTopic)),
            PayloadMap  = jsx:decode(Payload, [return_maps]),
            HeadersBin = maps:keys(PayloadMap),
            Headers = string:join(["" ++ cts(X) ++ "" || X <- HeadersBin], ","),
            Values = string:join(["'" ++ cts(X) ++ "'" || X <- lists:map( fun(HeaderBin) -> maps:get(HeaderBin, PayloadMap) end,HeadersBin)], ","),
            Query = io_lib:format("INSERT INTO  ~s.~s (~s) VALUES(~s) ~n ;", [Schema, Table, Headers, Values] ),
            case squery(Query) of
            {error, ErrMsg} ->
              FullErrMsg = io_lib:format("failed to insert into table: SQL statement ~s~n ErrMsg: ~p~n",[Query,ErrMsg]),
              execute_error_query(MqttTime, MqttClientID, MqttHeaders, FullTopic, Payload, ErrorSchema, ErrorTable, FullErrMsg );
            {ok, Result} ->
              {ok, Result};
            _ ->
              ok
            end;
          false ->
            execute_error_query(MqttTime, MqttClientID, MqttHeaders, FullTopic, Payload, ErrorSchema, ErrorTable, "malformed topic: tableno or schemano is greater than length of / separator split topic" )
        end;
      false ->
            execute_error_query(MqttTime, MqttClientID, MqttHeaders, FullTopic, Payload, ErrorSchema, ErrorTable, "payload is not in JSON format " )
    end.


execute_error_query(MqttTime, MqttClientID, MqttHeaders, Topic, Payload, ErrorSchema, ErrorTable, ErrorMsg ) ->
  ErrorQuery = io_lib:format("INSERT INTO ~s.~s (mqtt_time, client_id, headers, topic, payload, error_message) VALUES ($1, $2, $3, $4, $5, $6)",[ErrorSchema, ErrorTable]),
  case equery(ErrorQuery,[erlang:now(), MqttClientID, cts(MqttHeaders),Topic, cts(Payload), ErrorMsg]) of
    {error, ErrMsg} ->
      io:format("Failed to insert error message~n"),
      io:format("Query Statement: ~s~n", [ErrorQuery]),
      io:format("Params~ntime: ~p~nlient_id~p~nmqtt_headers:~p~ntopic~p~npayload:~s~n", [erlang:now(), MqttClientID, MqttHeaders,Topic, Payload]),
      io:format("Error message: ~p~n", [ErrMsg]);
    {ok, Result} ->
      {ok, Result};
    _ ->
      ok
  end.

squery(Sql) ->
  poolboy:transaction(mqtt2pgsql_psql_pool_worker, fun(Worker) ->
      gen_server:call(Worker, {squery, Sql})
  end).

equery(Stmt, Params) ->
  poolboy:transaction(mqtt2pgsql_psql_pool_worker, fun(Worker) ->
      gen_server:call(Worker, {equery, Stmt, Params})
  end).

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
