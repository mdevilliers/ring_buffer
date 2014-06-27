-module (tiered_ring_buffer_server).

-behaviour(gen_server).

-export ([start_link/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {table, length, name, cursor = 0, slots_full = 0 }).

%% Public API
start_link(Name, Length) when is_integer(Length), is_atom(Name) ->
  gen_server:start(?MODULE, [Name, Length], []).

init([Name, Length]) ->

	TableId = ets:new(Name, [ordered_set]),
	[ets:insert(TableId, [{N, now(), <<>>}]) || N <- lists:seq(1, Length - 1)],
  	{ok, #state{table = TableId, length = Length,
              name = Name}}.


handle_call(clear, _,  #state{table = TableId, length = Length, name = Name}) ->
  true = ets:delete_all_objects(TableId),
 {reply, ok, #state{table = TableId, length = Length,
              name = Name}};

handle_call(count, _,  #state{slots_full = Count} = State) ->
 {reply, Count, State};

handle_call(size, _,  #state{length = Length} = State) ->
 {reply, Length, State};

handle_call(delete, _,  #state{table = TableId} = State) ->
  true = ets:delete(TableId),
  {stop, normal, shutdown_ok, State};

handle_call({select, Count}, _, #state{ length = Length} = State) when Count > Length ->
 {reply, {error, invalid_length}, State};

handle_call({select, Count}, _, #state{ table = TableId, 
                                        length = Length, 
                                        cursor = Cursor } = State) ->
 Cursor1 = (Cursor ) rem Length,
 Range = get_looped_range(Length, Cursor1 , Count,TableId),
 {reply, Range, State};

handle_call(select_all, _, #state{  table = TableId, 
                                    length = Length, 
                                    cursor = Cursor } = State) ->
 Cursor1 = Cursor rem Length,
 Range = get_looped_range(Length, Cursor1, Length,TableId),
 {reply, Range, State};

handle_call({add, Data}, _, #state{    table = TableId,
                                       length = Length, 
                                       cursor = Cursor,
                                       slots_full = Count } = State) ->
  Cursor1 = Cursor rem Length,
  ets:insert(TableId, {Cursor1, now(), Data}),

  % track number of slots full
  case Count =:= Length of
    false ->
      Count1 = Count + 1;
    true ->
      Count1 = Count 
  end,
  {reply, ok, State#state{cursor = Cursor + 1, slots_full = Count1}};

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
get_looped_range(Length, Position, MaxResults,TableId) when is_integer(Length), 
                                                    is_integer(Position), 
                                                    is_integer(MaxResults) ->
  Sequence = get_range(Length, Position, MaxResults,TableId),
  %io:format(user, "~n1. Length : ~p,Position : ~p, MaxResults : ~p, Sequence : ~p~n", [Length,Position, MaxResults, Sequence]),
  lists:reverse(Sequence).

get_range(TotalSlots, Position, MaxResults,TableId) when MaxResults =< TotalSlots,
                                                      is_integer(TotalSlots) ->
  do_get_range(TotalSlots, Position-1, MaxResults,TableId, []).

do_get_range(_, _, 0,_, Acc) ->
  Acc;
do_get_range(TotalSlots, -1, MaxResults, TableId, Acc) ->
  do_get_range(TotalSlots, TotalSlots-1, MaxResults, TableId, Acc);
do_get_range(TotalSlots, Position, MaxResults, TableId, Acc) ->
  [{_,_, R }]  = ets:slot(TableId, Position),
  do_get_range(TotalSlots,Position - 1, MaxResults -1, TableId,[R|Acc]).
