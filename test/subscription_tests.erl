-module (subscription_tests).

-include_lib("eunit/include/eunit.hrl").

-export ([process_loop/1]).

add_and_remove_subscription_test() ->
	ring_buffer_sup:start_link(),
	Me = self(),
	
	% set uo and check if empty
	{ok, Ref} = ring_buffer:new(add_subscription_test),
	{empty} = ring_buffer:list_subscriptions(Ref),
	
	% add a subscription and unsubscribe - check empty
	ok = ring_buffer:subscribe(Ref, {loop}),
	{ok,[{subscription, Me ,{loop}}]} = ring_buffer:list_subscriptions(Ref),
	ok = ring_buffer:unsubscribe(Ref, {loop}),
    {empty} = ring_buffer:list_subscriptions(Ref),


    % make some more subscriptions including one in aother process
    ok = ring_buffer:subscribe(Ref, {empty}),
    ok = ring_buffer:subscribe(Ref, {loop}),
    Pid = spawn(?MODULE, process_loop , [Ref]),
    Pid ! {subscribe, {empty}},

	timer:sleep(100),
	
	% check all the subscriptions are all there
    {ok,Subscriptions} = ring_buffer:list_subscriptions(Ref),
    %io:format(user, "Subscriptions ~p~n", [Subscriptions]),
    ?assertEqual(length(Subscriptions), 3),
	
	% remove my subscriptions
	ok = ring_buffer:unsubscribe_all(Ref),

	% check there is one left
	{ok,[{subscription,_,{empty}}]} = ring_buffer:list_subscriptions(Ref),

	% kill it
	Pid ! {die},
	timer:sleep(100),

	% check there are no subscriptions left
	{empty} = ring_buffer:list_subscriptions(Ref).

unsubscribe_all_when_empty_is_ok_test() ->
	ring_buffer_sup:start_link(),	
	{ok, Ref} = ring_buffer:new(unsubscribe_all_when_empty_is_ok_test),
	ok = ring_buffer:unsubscribe_all(Ref),
	{empty} = ring_buffer:list_subscriptions(Ref),
	ok = ring_buffer:unsubscribe_all(Ref),
	{empty} = ring_buffer:list_subscriptions(Ref).


check_clear_event_emitted_test()->
	ring_buffer_sup:start_link(),
	RingBufferName = check_clear_event_emitted_test, 
	Subscription = {empty},	
	{ok, Ref} = ring_buffer:new(RingBufferName),

	ok = ring_buffer:subscribe(Ref, Subscription),
	ok = ring_buffer:clear(Ref),

	receive
		{RingBufferName, Ref, Subscription} ->
			?assert(true)
		after
		500 ->
			?assert(false)
	end.

check_full_event_emitted_test()->
	ring_buffer_sup:start_link(),
	Subscription = {loop},
	RingBufferName = check_full_event_emitted_test, 
	Entries = 2,	
	{ok, Ref} = ring_buffer:new(RingBufferName, Entries),

	ok = ring_buffer:subscribe(Ref, Subscription),
	% add 4 messages .... check for 2 {loop} messages
	ok = ring_buffer:add(Ref, 1 ),
	ok = ring_buffer:add(Ref, 1 ),
	ok = ring_buffer:add(Ref, 1 ),
	ok = ring_buffer:add(Ref, 1 ),

	receive
		{RingBufferName, Ref, Subscription} ->
			?assert(true),
				receive
					{RingBufferName, Ref, Subscription} ->
						?assert(true)
				after
					500 ->
					?assert(false)
				end
		after
		500 ->
			?assert(false)
	end.

check_every_event_emitted_test() ->
	ring_buffer_sup:start_link(),
	Subscription = {every,5},
	RingBufferName = check_every_event_emitted_test, 
	Entries = 10,	
	{ok, Ref} = ring_buffer:new(RingBufferName, Entries),

	ok = ring_buffer:subscribe(Ref, Subscription),

	ok = ring_buffer:add(Ref, 1 ),
	ok = ring_buffer:add(Ref, 1 ),
	ok = ring_buffer:add(Ref, 1 ),
	ok = ring_buffer:add(Ref, 1 ),

	% there shouldn't be a message
	receive
		{RingBufferName, Ref, Subscription} ->
			?assert(false)
		after
		100 ->
			?assert(true)
	end,

	ok = ring_buffer:add(Ref, 1 ),

	% there should be a message
	receive
		{RingBufferName, Ref, Subscription} ->
			?assert(true)
		after
		500 ->
			?assert(false)
	end,

	ok = ring_buffer:add(Ref, 1 ),

	% there shouldn't be a message
	receive
		{RingBufferName, Ref, Subscription} ->
			?assert(false)
		after
		100 ->
			?assert(true)
	end.

invalid_and_valid_specifications_test() ->
	ring_buffer_sup:start_link(),
	{ok, Ref} = ring_buffer:new(invalid_and_valid_specifications_test),
	ok = ring_buffer:subscribe(Ref,  {empty}),
	ok = ring_buffer:subscribe(Ref,  {loop}),
	{invalid_specification} = ring_buffer:subscribe(Ref, {xxxx}).

% test helpers
process_loop(Ref) ->
	receive
		{subscribe, SubscriptionInfo} ->
			% io:format(user, "process ~p~n", [self()]),
			ok = ring_buffer:subscribe(Ref, SubscriptionInfo),
			process_loop(Ref);
		{die} ->
			ok
	end.