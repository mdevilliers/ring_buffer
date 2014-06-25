-module (tiered_ring_buffer_server).

-behaviour(gen_server).

-export ([start_link/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {table, length, name, cursor = 0}).

%% Public API
start_link(Name, Length) when is_integer(Length), is_atom(Name) ->
  gen_server:start(?MODULE, [Name, Length], []).

init([Name, Length]) ->

	TableId = ets:new(Name, [ordered_set]),
	[ets:insert(TableId, [{N, now(), <<>>}]) || N <- lists:seq(1, Length - 1)],
  	{ok, #state{table = TableId, length = Length,
              name = Name, cursor = 0}}.

handle_call({select}, _From, #state{table = TableId, length = Length, cursor = Cursor} = State) ->
 % loop back through the table, decrementiing the length
 % at pos 0 
 Cursor1 = Cursor rem Length,
 Range = get_looped_range(Length - 1,Cursor1),
 io:format(user, "Range : ~p~n", [Range]),
 Results = ets:tab2list(TableId),

 {reply, Results, State};
handle_call({add, Data}, _From, #state{table = TableId,
                                       length = Length, cursor = Cursor} = State) ->
  Cursor1 = Cursor rem Length,
  ets:insert(TableId, {Cursor1, now(), Data}),

   io:format(user, "~p ~p ~n", [Data, Cursor1]),
  {reply, ok, State#state{cursor = Cursor + 1}};
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

% % Private
% collect(0, _, _, Acc) ->
%   Acc;
% collect(Current, Length, TableId, Acc) ->
%   ets:slot(TableId, TableId)


% ensure_table_exists(Name) ->
% 	try 
% 		TableId = ets:new(Name, [ordered_set, named_table]),
% 	catch
% 		error:badarg -> init_mytables()
% 	end.
get_looped_range(Length, Position) when is_integer(Length), is_integer(Position) ->
  Range = lists:seq(0,Length),
  {One,Two} = lists:split(Position , Range),
  Sequence = lists:flatten([Two|One]),
  Sequence.