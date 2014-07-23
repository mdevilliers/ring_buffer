-module (ring_buffer_server).

-behaviour(gen_server).

-export ([start_link/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
% private
-export ([emit_message/4]).

-record(state, {adapter, length, name, cursor = 0, slots_full = 0 , subscriptions = []}).
-record (subscription, {pid , spec}).

%% Public API
start_link(Name, Length) when is_integer(Length), is_atom(Name) ->
  gen_server:start(?MODULE, [Name, Length], []).

% Private
init([Name, Length]) ->
	Adapter = ring_buffer_store:new(ets,Name),
	[Adapter:insert([{N, <<>>}]) || N <- lists:seq(1, Length - 1)],
  {ok, #state{adapter = Adapter, 
              length = Length,
              name = Name}}.

handle_call(clear, _,  #state{adapter = Adapter, length = Length, name = Name, subscriptions = Subscriptions}) ->
  [Adapter:insert([{N, <<>>}]) || N <- lists:seq(1, Length - 1)],
  emit({empty}, Name, 1, Subscriptions),
  {reply, ok, #state{adapter = Adapter, 
              length = Length,
              name = Name}};

handle_call(count, _,  #state{slots_full = Count} = State) -> {reply, Count, State};

handle_call(size, _,  #state{length = Length} = State) -> {reply, Length, State};

handle_call(delete, _,  #state{adapter = Adapter} = State) ->
  Adapter:delete(),
  {stop, normal, shutdown_ok, State};

handle_call({select, Count}, _, State) when Count < 0 ->
 {reply, {error, invalid_length}, State};
handle_call({select, Count}, _, #state{ length = Length} = State) when Count > Length ->
 {reply, {error, invalid_length}, State};
handle_call({select, Count}, _, #state{ length = Length, cursor = Cursor, slots_full = Slots_full} = State) 
                                  when Count > Cursor rem Length, Slots_full < Length ->
 {reply, {error, invalid_length}, State};

handle_call({select, Count}, _, #state{ adapter = Adapter, 
                                        length = Length, 
                                        cursor = Cursor } = State) ->
 Cursor1 = Cursor rem Length,
 Results = scan(Length, Cursor1, Count, Adapter),
 {reply, Results, State};

handle_call(select_all, _, #state{  adapter = Adapter,
                                    length = Length, 
                                    cursor = Cursor } = State) ->
 Cursor1 = Cursor rem Length,
 Range = scan(Length, Cursor1, Length, Adapter),
 {reply, Range, State};

handle_call({add, Data}, _, #state{    adapter = Adapter,
                                       length = Length, 
                                       cursor = Cursor,
                                       slots_full = Count,
                                       name = Name,
                                       subscriptions = Subscriptions } = State) ->
  Current = Cursor rem Length,
  Adapter:insert({Current, Data}),

  Next = Cursor + 1 rem Length,

  emit({every}, Name, Next, Subscriptions),
  case Next rem Length  of
    0 ->
      emit({loop}, Name, Next, Subscriptions);
    _ -> ok
  end,

  {reply, ok, State#state{cursor = Cursor + 1, slots_full = track_full_slots(Length, Count)}};

%% subscriptions
handle_call({subscribe, Pid, Spec}, _, #state{ subscriptions = Subscriptions} = State) ->

  case is_valid_specification(Spec) of
    false ->
      Response = {invalid_specification},
      State1 = State;
    true ->
      erlang:monitor(process, Pid), % TODO consider tracking pids
      NewSubscription = #subscription{pid = Pid, spec = Spec},
      State1 = State#state{ subscriptions = [NewSubscription | Subscriptions]},
      Response = ok
  end,
  {reply, Response, State1};

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

handle_info({'DOWN', _, process, Pid, normal},  #state{ subscriptions = Subscriptions} = State) ->
  State1 = State#state{ subscriptions = remove_all_subscriptions_for_pid(Subscriptions, Pid)},
  {noreply, State1};
handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

% helpers
scan(Length, Position, MaxResults, Adapter) when is_integer(Length), 
                                                 is_integer(Position), 
                                                 is_integer(MaxResults),
                                                 MaxResults =< Length ->
  lists:reverse(get_range(Length, Position-1, MaxResults, Adapter, [])).  

get_range(_, _, 0,_, Acc) ->
  Acc;
get_range(TotalSlots, -1, MaxResults, Adapter, Acc) ->
  get_range(TotalSlots, TotalSlots-1, MaxResults, Adapter, Acc);
get_range(TotalSlots, Position, MaxResults, Adapter, Acc) ->
  Value = Adapter:get(Position),
  get_range(TotalSlots,Position - 1, MaxResults -1, Adapter,[Value|Acc]).

track_full_slots(TotalSlots, TotalSlots) when is_integer(TotalSlots)-> TotalSlots;
track_full_slots(_, CurrentSlot) when is_integer(CurrentSlot)-> CurrentSlot + 1 .

% subscription helpers
remove_all_subscriptions_for_pid(Subscriptions, Pid) when is_pid(Pid), is_list(Subscriptions) ->
  lists:filter(fun(#subscription{pid = SubPid}) -> Pid =/= SubPid end, Subscriptions).

remove_subscription_from_list(Subscription, Subscriptions) when is_record(Subscription, subscription), is_list(Subscriptions) ->
  lists:delete(Subscription, Subscriptions).

emit(_, _, _,[])-> ok;
emit(Message, Name, Current, Subscriptions) when is_list(Subscriptions) ->
  NeedToKnow = filter_subscriptions_by_type(Message, Current, Subscriptions),
  emit_messages(Name, NeedToKnow).

filter_subscriptions_by_type({every}, Current, Subscriptions) when is_integer(Current),
                                                                   is_list(Subscriptions) ->
  lists:filter(fun(#subscription{spec = Spec}) -> 
                case Spec of
                   {every, T} ->  Current rem T =:= 0 ;
                   _ -> false
                end
              end, Subscriptions);

filter_subscriptions_by_type(Message, _, Subscriptions) when is_list(Subscriptions)->
  lists:filter(fun(#subscription{spec = Spec}) -> Spec =:= Message end, Subscriptions).

emit_messages(_, []) -> ok ;
emit_messages(Name, Subscriptions) when is_list(Subscriptions) ->
  lists:map(fun(#subscription{pid = Pid, spec= Spec}) -> emit_message(Spec, self(), Pid, Name) end, Subscriptions).

emit_message({every, N}, Self, Pid, Name) ->
  spawn( fun() ->  Pid ! { Name, Self, {every, N}, ring_buffer:select(Self, N) } end);
emit_message( Spec, Self, Pid, Name) ->
  spawn( fun() -> Pid ! { Name, Self, Spec } end).

is_valid_specification({loop}) -> true;
is_valid_specification({empty}) -> true;
is_valid_specification({every, N}) when is_integer(N) -> true;
is_valid_specification(_) -> false.