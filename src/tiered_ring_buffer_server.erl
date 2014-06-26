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

handle_call(delete, _,  #state{table = TableId} = State) ->
  true = ets:delete(TableId),
  {stop, normal, shutdown_ok, State};

handle_call({select, Count}, _, #state{table = TableId, length = Length, cursor = Cursor} = State) ->
 Cursor1 = (Cursor ) rem Length,
 Range = get_looped_range(Length, Cursor1 , Count),
 %io:format(user, "~nTable : ~p", [ets:tab2list(TableId)]),
 Results = lists:foldl(fun(Index, Acc) -> [{_,_, R }] = ets:slot(TableId, Index), [ R | Acc] end, [], Range),
 {reply, Results, State};

handle_call(select_all, _, #state{table = TableId, length = Length, cursor = Cursor} = State) ->
 Cursor1 = Cursor rem Length,
 Range = get_looped_range(Length, Cursor1, Length),
 Results = lists:foldl(fun(Index, Acc) -> [{_,_, R }] = ets:slot(TableId, Index), [ R | Acc] end, [], Range),
 {reply, Results, State};
handle_call({add, Data}, _, #state{table = TableId,
                                       length = Length, cursor = Cursor} = State) ->
  Cursor1 = Cursor rem Length,
  ets:insert(TableId, {Cursor1, now(), Data}),

  % io:format(user, "~p ~p ~n", [Data, Cursor1]),
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

% Private
get_looped_range(Length, Position, MaxResults) when is_integer(Length), 
                                                    is_integer(Position), 
                                                    is_integer(MaxResults) ->
  Sequence = get_range(Length, Position, MaxResults),
  io:format(user, "~n1. Length : ~p,Position : ~p, MaxResults : ~p, Sequence : ~p~n", [Length,Position, MaxResults, Sequence]),
  Sequence.

get_range(TotalSlots, Position, MaxResults) when MaxResults =< TotalSlots,
                                                      is_integer(TotalSlots) ->
  do_get_range(TotalSlots, Position-1, MaxResults, []).

do_get_range(_, _, 0, Acc) ->
  Acc;
do_get_range(TotalSlots, -1, MaxResults,Acc) ->
  do_get_range(TotalSlots,TotalSlots-1, MaxResults,Acc);
do_get_range(TotalSlots, Position, MaxResults,Acc) ->
  do_get_range(TotalSlots,Position - 1, MaxResults -1, [ Position|Acc]).
