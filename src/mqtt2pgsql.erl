%%--------------------------------------------------------------------
%% Copyright (c) 2020 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(mqtt2pgsql).

-include_lib("emqx/include/emqx.hrl").

-export([load/1, unload/1]).

-export([connect/2, connectPid/1, closeDbConnction/1]). %% Client Lifecircle Hooks
		     % -export([ on_client_connect/3
		     %         , on_client_connack/4
		     %         , on_client_connected/3
		     %         , on_client_disconnected/4
		     %         , on_client_authenticate/3
		     %         , on_client_check_acl/5
		     %         , on_client_subscribe/4
		     %         , on_client_unsubscribe/4
		     %         ]).

%% Session Lifecircle Hooks
% -export([ on_session_created/3
%         , on_session_subscribed/4
%         , on_session_unsubscribed/4
%         , on_session_resumed/3
%         , on_session_discarded/3
%         , on_session_takeovered/3
%         , on_session_terminated/4
%         ]).

%% Message Pubsub Hooks
-export([on_message_publish/2]).        % , on_message_delivered/3
					% , on_message_acked/3
					% , on_message_dropped/4
-export([cts/1, write/3]).

%% Called when the plugin application start
load(Env) ->
    connectPid(Env),
    % emqx:hook('client.connect',      {?MODULE, on_client_connect, [Env]}),
    % emqx:hook('client.connack',      {?MODULE, on_client_connack, [Env]}),
    % emqx:hook('client.connected',    {?MODULE, on_client_connected, [Env]}),
    % emqx:hook('client.disconnected', {?MODULE, on_client_disconnected, [Env]}),
    % emqx:hook('client.authenticate', {?MODULE, on_client_authenticate, [Env]}),
    % emqx:hook('client.check_acl',    {?MODULE, on_client_check_acl, [Env]}),
    % emqx:hook('client.subscribe',    {?MODULE, on_client_subscribe, [Env]}),
    % emqx:hook('client.unsubscribe',  {?MODULE, on_client_unsubscribe, [Env]}),
    % emqx:hook('session.created',     {?MODULE, on_session_created, [Env]}),
    % emqx:hook('session.subscribed',  {?MODULE, on_session_subscribed, [Env]}),
    % emqx:hook('session.unsubscribed',{?MODULE, on_session_unsubscribed, [Env]}),
    % emqx:hook('session.resumed',     {?MODULE, on_session_resumed, [Env]}),
    % emqx:hook('session.discarded',   {?MODULE, on_session_discarded, [Env]}),
    % emqx:hook('session.takeovered',  {?MODULE, on_session_takeovered, [Env]}),
    % emqx:hook('session.terminated',  {?MODULE, on_session_terminated, [Env]}),
    % emqx:hook('message.delivered',   {?MODULE, on_message_delivered, [Env]}),
    % emqx:hook('message.acked',       {?MODULE, on_message_acked, [Env]}),
    % emqx:hook('message.dropped',     {?MODULE, on_message_dropped, [Env]}),
    emqx:hook('message.publish',
	      {?MODULE, on_message_publish, [Env]}).

%%--------------------------------------------------------------------
%% Client Lifecircle Hooks
%%--------------------------------------------------------------------

% on_client_connect(ConnInfo = #{clientid := ClientId}, Props, _Env) ->
%     io:format("Client(~s) connect, ConnInfo: ~p, Props: ~p~n",
%               [ClientId, ConnInfo, Props]),
%     {ok, Props}.

% on_client_connack(ConnInfo = #{clientid := ClientId}, Rc, Props, _Env) ->
%     io:format("Client(~s) connack, ConnInfo: ~p, Rc: ~p, Props: ~p~n",
%               [ClientId, ConnInfo, Rc, Props]),
%     {ok, Props}.

% on_client_connected(ClientInfo = #{clientid := ClientId}, ConnInfo, _Env) ->
%     io:format("Client(~s) connected, ClientInfo:~n~p~n, ConnInfo:~n~p~n",
%               [ClientId, ClientInfo, ConnInfo]).

% on_client_disconnected(ClientInfo = #{clientid := ClientId}, ReasonCode, ConnInfo, _Env) ->
%     io:format("Client(~s) disconnected due to ~p, ClientInfo:~n~p~n, ConnInfo:~n~p~n",
%               [ClientId, ReasonCode, ClientInfo, ConnInfo]).

% on_client_authenticate(_ClientInfo = #{clientid := ClientId}, Result, _Env) ->
%     io:format("Client(~s) authenticate, Result:~n~p~n", [ClientId, Result]),
%     {ok, Result}.

% on_client_check_acl(_ClientInfo = #{clientid := ClientId}, Topic, PubSub, Result, _Env) ->
%     io:format("Client(~s) check_acl, PubSub:~p, Topic:~p, Result:~p~n",
%               [ClientId, PubSub, Topic, Result]),
%     {ok, Result}.

% on_client_subscribe(#{clientid := ClientId}, _Properties, TopicFilters, _Env) ->
%     io:format("Client(~s) will subscribe: ~p~n", [ClientId, TopicFilters]),
%     {ok, TopicFilters}.

% on_client_unsubscribe(#{clientid := ClientId}, _Properties, TopicFilters, _Env) ->
%     io:format("Client(~s) will unsubscribe ~p~n", [ClientId, TopicFilters]),
%     {ok, TopicFilters}.

%%--------------------------------------------------------------------
%% Session Lifecircle Hooks
%%--------------------------------------------------------------------

% on_session_created(#{clientid := ClientId}, SessInfo, _Env) ->
%     io:format("Session(~s) created, Session Info:~n~p~n", [ClientId, SessInfo]).

% on_session_subscribed(#{clientid := ClientId}, Topic, SubOpts, _Env) ->
%     io:format("Session(~s) subscribed ~s with subopts: ~p~n", [ClientId, Topic, SubOpts]).

% on_session_unsubscribed(#{clientid := ClientId}, Topic, Opts, _Env) ->
%     io:format("Session(~s) unsubscribed ~s with opts: ~p~n", [ClientId, Topic, Opts]).

% on_session_resumed(#{clientid := ClientId}, SessInfo, _Env) ->
%     io:format("Session(~s) resumed, Session Info:~n~p~n", [ClientId, SessInfo]).

% on_session_discarded(_ClientInfo = #{clientid := ClientId}, SessInfo, _Env) ->
%     io:format("Session(~s) is discarded. Session Info: ~p~n", [ClientId, SessInfo]).

% on_session_takeovered(_ClientInfo = #{clientid := ClientId}, SessInfo, _Env) ->
%     io:format("Session(~s) is takeovered. Session Info: ~p~n", [ClientId, SessInfo]).

% on_session_terminated(_ClientInfo = #{clientid := ClientId}, Reason, SessInfo, _Env) ->
%     io:format("Session(~s) is terminated due to ~p~nSession Info: ~p~n",
%               [ClientId, Reason, SessInfo]).

%%--------------------------------------------------------------------
%% Message PubSub Hooks
%%--------------------------------------------------------------------

%% Transform message and return
on_message_publish(Message = #message{topic =
					  <<"$SYS/", _/binary>>},
		   Env) ->
    {ok, Message};
on_message_publish(Message, Env) ->
    % io:format("Publish ~s~n", [emqx_message:format(Message)]),
    MessageMaps = emqx_message:to_map(Message),
    % io:format("Publish ~p~n", [MessageMaps]),
    % io:format("Publish ~p~n", [emqx_message:to_list(Message)]),
    % io:format("Publish ~p~n", [Env]),



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
            io:format("Query - ~s~n", [Query]),
            mqtt2pgsql:write(list_to_atom(lists:flatten(io_lib:format("connection_~p", [rand:uniform(10)]))), Query, Env);
          false ->
            io:format("SchemaNo or TableNo or both worng Topic list - ~p    SchemaNo - ~p   TableNo -  ~p ~n", [Topic, SchemaNo, TableNo] )
        end;
      false -> 
        io:format(" Message is not JSON , Topic - ~p,   Payload - ~p~n" , [emqx_message:topic(Message), Payload])
    end,

    % io:format("Env ~p~n", [Env]),
    % mqtt2pgsql:connect(),
    {ok, Message}.

% on_message_dropped(#message{topic = <<"$SYS/", _/binary>>}, _By, _Reason, _Env) ->
%     ok;
% on_message_dropped(Message, _By = #{node := Node}, Reason, _Env) ->
%     io:format("Message dropped by node ~s due to ~s: ~s~n",
%               [Node, Reason, emqx_message:format(Message)]).

% on_message_delivered(_ClientInfo = #{clientid := ClientId}, Message, _Env) ->
%     io:format("Message delivered to client(~s): ~s~n",
%               [ClientId, emqx_message:format(Message)]),
%     {ok, Message}.

% on_message_acked(_ClientInfo = #{clientid := ClientId}, Message, _Env) ->
%     io:format("Message acked by client(~s): ~s~n",
%               [ClientId, emqx_message:format(Message)]).
write(NamePid, Query,Env) ->
  io:format("Name of Connection -  ~p~n", [NamePid]), 
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
    % emqx:unhook('client.connect',      {?MODULE, on_client_connect}),
    % emqx:unhook('client.connack',      {?MODULE, on_client_connack}),
    % emqx:unhook('client.connected',    {?MODULE, on_client_connected}),
    % emqx:unhook('client.disconnected', {?MODULE, on_client_disconnected}),
    % emqx:unhook('client.authenticate', {?MODULE, on_client_authenticate}),
    % emqx:unhook('client.check_acl',    {?MODULE, on_client_check_acl}),
    % emqx:unhook('client.subscribe',    {?MODULE, on_client_subscribe}),
    % emqx:unhook('client.unsubscribe',  {?MODULE, on_client_unsubscribe}),
    % emqx:unhook('session.created',     {?MODULE, on_session_created}),
    % emqx:unhook('session.subscribed',  {?MODULE, on_session_subscribed}),
    % emqx:unhook('session.unsubscribed',{?MODULE, on_session_unsubscribed}),
    % emqx:unhook('session.resumed',     {?MODULE, on_session_resumed}),
    % emqx:unhook('session.discarded',   {?MODULE, on_session_discarded}),
    % emqx:unhook('session.takeovered',  {?MODULE, on_session_takeovered}),
    % emqx:unhook('session.terminated',  {?MODULE, on_session_terminated}),
    % emqx:unhook('message.delivered',   {?MODULE, on_message_delivered}),
    % emqx:unhook('message.acked',       {?MODULE, on_message_acked}),
    % emqx:unhook('message.dropped',     {?MODULE, on_message_dropped}),
    closeDbConnction(Env),
    emqx:unhook('message.publish',{?MODULE, on_message_publish}).

