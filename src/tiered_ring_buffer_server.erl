-module (tiered_ring_buffer_server).

-behaviour(gen_server).

-export ([start_link/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {table, length, name, cursor = 0, slots_full = 0 }).

%% Public API
start_link(Name, Length) when is_integer(Length), is_atom(Name) ->
  gen_server:start(?MODULE, [Name, Length], []).

% Private
init([Name, Length]) ->
	TableId = new(Name),
	[insert(TableId, [{N, <<>>}]) || N <- lists:seq(1, Length - 1)],
  	{ok, #state{table = TableId, length = Length,
              name = Name}}.

handle_call(clear, _,  #state{table = TableId, length = Length, name = Name}) ->
  remove_all(TableId) ,
  {reply, ok, #state{table = TableId, length = Length,
              name = Name}};

handle_call(count, _,  #state{slots_full = Count} = State) -> {reply, Count, State};

handle_call(size, _,  #state{length = Length} = State) -> {reply, Length, State};

handle_call(delete, _,  #state{table = TableId} = State) ->
  true = ets:delete(TableId),
  {stop, normal, shutdown_ok, State};


% handle_call({range, _, Count}, _, State) when Count < 0 ->
%  {reply, {error, invalid_length}, State};
% handle_call({range, _, Count}, _, #state{ slots_full = SlotsFull} = State) when Count > SlotsFull ->
%  {reply, {error, invalid_length}, State};
% handle_call({range, From, Count}, _, #state{cursor = Cursor, length = Length} = State) when From - Count > Cursor rem Length ->
%   io:format(user, "From : ~p Count : ~p Cursor : ~p Pos : ~p~n", [From,Count,Cursor, Cursor rem Length]),
%   {reply, {error, invalid_lengthxx}, State};
% handle_call({range, _, Count}, _, #state{ length = Length} = State) when Count > Length ->
%  {reply, {error, invalid_length}, State};

% handle_call({range, From, Count}, _, #state{  table = TableId, 
%                                               length = Length } = State) ->
%  Cursor = From rem Length,
%  Results = scan(Length, Cursor, Count, TableId, Cursor),
%  {reply, Results, State};

handle_call({select, Count}, _, State) when Count < 0 ->
 {reply, {error, invalid_length}, State};
handle_call({select, Count}, _, #state{ length = Length} = State) when Count > Length ->
 {reply, {error, invalid_length}, State};

handle_call({select, Count}, _, #state{ table = TableId, 
                                        length = Length, 
                                        cursor = Cursor } = State) ->
 Cursor1 = Cursor rem Length,
 Results = scan(Length, Cursor1, Count, TableId, Cursor1),
 {reply, Results, State};

handle_call(select_all, _, #state{  table = TableId, 
                                    length = Length, 
                                    cursor = Cursor } = State) ->
 Cursor1 = Cursor rem Length,
 Range = scan(Length, Cursor1, Length, TableId, Cursor1),
 {reply, Range, State};

handle_call({add, Data}, _, #state{    table = TableId,
                                       length = Length, 
                                       cursor = Cursor,
                                       slots_full = Count } = State) ->
  Current = Cursor rem Length,
  insert(TableId, {Current, Data}),
  {reply, ok, State#state{cursor = Cursor + 1, slots_full = track_full_slots(Length, Count)}};

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


scan(Length, Position, MaxResults, TableId, Head) when is_integer(Length), 
                                                    is_integer(Position), 
                                                    is_integer(MaxResults) ->
  case get_range(Length, Position, MaxResults, TableId, Head) of
       Sequence when is_list(Sequence) ->
          lists:reverse(Sequence);
      Error ->
          Error
  end.   

get_range(TotalSlots, Position, MaxResults, TableId, Head) when MaxResults =< TotalSlots,
                                                      is_integer(TotalSlots) ->
  do_get_range(TotalSlots, Position-1, MaxResults, TableId, Head, []).

do_get_range(_, _, 0,_, _, Acc) ->
  Acc;
do_get_range(TotalSlots, -1, MaxResults, TableId, Head, Acc) ->
  do_get_range(TotalSlots, TotalSlots-1, MaxResults, TableId, Head, Acc);
do_get_range(TotalSlots, Position, MaxResults, TableId, Head, Acc) ->
  Value = get(TableId, Position),
  do_get_range(TotalSlots,Position - 1, MaxResults -1, TableId, Head,[Value|Acc]).

track_full_slots(TotalSlots, TotalSlots) when is_integer(TotalSlots)-> TotalSlots;
track_full_slots(_, CurrentSlot) when is_integer(CurrentSlot)-> CurrentSlot + 1 .

% ets implementation
new(Name) ->
  ets:new(Name, [ordered_set]).

get(TableId, Position) ->
   [{_, Value }]  = ets:slot(TableId, Position),
   Value.

remove_all(TableId) ->
  true = ets:delete(TableId).

insert(TableId, Value) ->
 ets:insert(TableId, Value).