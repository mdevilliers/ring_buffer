-module (tiered_ring_buffer_server).

-behaviour(gen_server).

-export ([start_link/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {table, length, name, cursor = 0, slots_full = 0 , subscriptions = []}).
-record (subscription, {pid , spec}).

%% Public API
start_link(Name, Length) when is_integer(Length), is_atom(Name) ->
  gen_server:start(?MODULE, [Name, Length], []).

% Private
init([Name, Length]) ->
	TableId = new(Name),
	[insert(TableId, [{N, <<>>}]) || N <- lists:seq(1, Length - 1)],
  {ok, #state{table = TableId, 
              length = Length,
              name = Name}}.

handle_call(clear, _,  #state{table = TableId, length = Length, name = Name}) ->
  [insert(TableId, [{N, <<>>}]) || N <- lists:seq(1, Length - 1)],
  {reply, ok, #state{table = TableId, 
              length = Length,
              name = Name}};

handle_call(count, _,  #state{slots_full = Count} = State) -> {reply, Count, State};

handle_call(size, _,  #state{length = Length} = State) -> {reply, Length, State};

handle_call(delete, _,  #state{table = TableId} = State) ->
  delete(TableId),
  {stop, normal, shutdown_ok, State};

handle_call({select, Count}, _, State) when Count < 0 ->
 {reply, {error, invalid_length}, State};
handle_call({select, Count}, _, #state{ length = Length} = State) when Count > Length ->
 {reply, {error, invalid_length}, State};
handle_call({select, Count}, _, #state{ length = Length, cursor = Cursor, slots_full = Slots_full} = State) when Count > Cursor rem Length, Slots_full < Length ->
 {reply, {error, invalid_length}, State};

handle_call({select, Count}, _, #state{ table = TableId, 
                                        length = Length, 
                                        cursor = Cursor } = State) ->
 Cursor1 = Cursor rem Length,
 Results = scan(Length, Cursor1, Count, TableId),
 {reply, Results, State};

handle_call(select_all, _, #state{  table = TableId, 
                                    length = Length, 
                                    cursor = Cursor } = State) ->
 Cursor1 = Cursor rem Length,
 Range = scan(Length, Cursor1, Length, TableId),
 {reply, Range, State};

handle_call({add, Data}, _, #state{    table = TableId,
                                       length = Length, 
                                       cursor = Cursor,
                                       slots_full = Count } = State) ->
  Current = Cursor rem Length,
  insert(TableId, {Current, Data}),
  {reply, ok, State#state{cursor = Cursor + 1, slots_full = track_full_slots(Length, Count)}};

%% subscription stuff
handle_call({subscribe, Pid, Spec}, _, #state{ subscriptions = Subscriptions} = State) ->
  erlang:monitor(process, Pid), % TODO consider trcking pids
  NewSubscription = #subscription{pid = Pid, spec = Spec},
  State1 = State#state{ subscriptions = [NewSubscription | Subscriptions]},
  {reply, ok, State1};

handle_call({unsubscribe, Pid, Spec}, _, #state{ subscriptions = Subscriptions} = State) ->
  State1 = State#state{ subscriptions = remove_subscription_from_list( #subscription{pid = Pid, spec = Spec} , Subscriptions)},
  {reply, ok, State1};

handle_call({unsubscribe_all, _}, _, #state{ subscriptions = []} = State) ->
  {reply, ok, State};
handle_call({unsubscribe_all, Pid}, _, #state{ subscriptions = Subscriptions} = State) ->
  State1 = State#state{ subscriptions = remove_all_subscriptions_for_pid(Subscriptions, Pid)},
  {reply, ok, State1};

handle_call({list_subscriptions}, _, #state{ subscriptions = []} = State) ->
  {reply, {empty}, State};
handle_call({list_subscriptions}, _, #state{ subscriptions = Subscriptions} = State) ->
  {reply, {ok, Subscriptions}, State};

handle_call(_Request, _From, State) ->
  {reply, ok, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info({'DOWN',_,process,Pid,normal},  #state{ subscriptions = Subscriptions} = State) ->
  State1 = State#state{ subscriptions = remove_all_subscriptions_for_pid(Subscriptions, Pid)},
  {noreply, State1};
handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

% helpers
scan(Length, Position, MaxResults, TableId) when is_integer(Length), 
                                                 is_integer(Position), 
                                                 is_integer(MaxResults),
                                                 MaxResults =< Length ->
  lists:reverse(get_range(Length, Position-1, MaxResults, TableId, [])).  

get_range(_, _, 0,_, Acc) ->
  Acc;
get_range(TotalSlots, -1, MaxResults, TableId, Acc) ->
  get_range(TotalSlots, TotalSlots-1, MaxResults, TableId, Acc);
get_range(TotalSlots, Position, MaxResults, TableId, Acc) ->
  Value = get(TableId, Position),
  get_range(TotalSlots,Position - 1, MaxResults -1, TableId,[Value|Acc]).

track_full_slots(TotalSlots, TotalSlots) when is_integer(TotalSlots)-> TotalSlots;
track_full_slots(_, CurrentSlot) when is_integer(CurrentSlot)-> CurrentSlot + 1 .

% ets implementation
new(Name) ->
  ets:new(Name, [ordered_set]).

get(TableId, Position) ->
  [{_, Value }]  = ets:slot(TableId, Position),
  Value.

delete(TableId) ->
  true = ets:delete(TableId).

insert(TableId, Value) ->
  ets:insert(TableId, Value).

% subsription helpers
remove_all_subscriptions_for_pid(Subscriptions, Pid) when is_pid(Pid), is_list(Subscriptions)->
  lists:filter(fun(#subscription{pid = SubPid}) -> Pid =/= SubPid end, Subscriptions).

remove_subscription_from_list(Subscription, Subscriptions) when is_record(Subscription, subscription), is_list(Subscriptions)->
  lists:delete(Subscription, Subscriptions).