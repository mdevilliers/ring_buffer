-module (subscription_tests).

-include_lib("eunit/include/eunit.hrl").

-export ([process_loop/1]).

add_and_remove_subscription_test() ->
	tiered_ring_buffer_sup:start_link(),
	Me = self(),
	
	% set uo and check if empty
	{ok, Ref} = tiered_ring_buffer:new(add_subscription_test),
	{empty} = tiered_ring_buffer:list_subscriptions(Ref),
	
	% add a subscription and unsubscribe - check empty
	ok = tiered_ring_buffer:subscribe(Ref, {loop}),
	{ok,[{subscription, Me ,{loop}}]} = tiered_ring_buffer:list_subscriptions(Ref),
	ok = tiered_ring_buffer:unsubscribe(Ref, {loop}),
    {empty} = tiered_ring_buffer:list_subscriptions(Ref),


    % make some more subscriptions including one in aother process
    ok = tiered_ring_buffer:subscribe(Ref, {empty}),
    ok = tiered_ring_buffer:subscribe(Ref, {loop}),
    Pid = spawn(?MODULE, process_loop , [Ref]),
    Pid ! {subscribe, {empty}},

	timer:sleep(100),
	
	% check all the subscriptions are all there
    {ok,Subscriptions} = tiered_ring_buffer:list_subscriptions(Ref),
    %io:format(user, "Subscriptions ~p~n", [Subscriptions]),
    ?assertEqual(length(Subscriptions), 3),
	
	% remove my subscriptions
	ok = tiered_ring_buffer:unsubscribe_all(Ref),

	% check there is one left
	{ok,[{subscription,_,{empty}}]} = tiered_ring_buffer:list_subscriptions(Ref),

	% kill it
	Pid ! {die},
	timer:sleep(100),

	% check there are no subscriptions left
	{empty} = tiered_ring_buffer:list_subscriptions(Ref).

unsubscribe_all_when_empty_is_ok_test() ->
	tiered_ring_buffer_sup:start_link(),	
	{ok, Ref} = tiered_ring_buffer:new(unsubscribe_all_when_empty_is_ok_test),
	ok = tiered_ring_buffer:unsubscribe_all(Ref),
	{empty} = tiered_ring_buffer:list_subscriptions(Ref),
	ok = tiered_ring_buffer:unsubscribe_all(Ref),
	{empty} = tiered_ring_buffer:list_subscriptions(Ref).


check_clear_event_emitted_test()->
	tiered_ring_buffer_sup:start_link(),
	Subscription = {empty},	
	{ok, Ref} = tiered_ring_buffer:new(check_clear_event_emitted_test),

	ok = tiered_ring_buffer:subscribe(Ref, Subscription),
	ok = tiered_ring_buffer:clear(Ref),

	receive
		Subscription ->
			?assert(true)
		after
		500 ->
			?assert(false)
	end.

check_full_event_emitted_test()->
	tiered_ring_buffer_sup:start_link(),
	Subscription = {loop},
	Entries = 2,	
	{ok, Ref} = tiered_ring_buffer:new(check_full_event_emitted_test, Entries),

	ok = tiered_ring_buffer:subscribe(Ref, Subscription),
	% add 4 messages .... check for 2 {full} messages
	ok = tiered_ring_buffer:add(Ref, 1 ),
	ok = tiered_ring_buffer:add(Ref, 1 ),
	ok = tiered_ring_buffer:add(Ref, 1 ),
	ok = tiered_ring_buffer:add(Ref, 1 ),

	receive
		Subscription ->
			?assert(true),
				receive
					Subscription ->
						?assert(true)
				after
					500 ->
					?assert(false)
				end
		after
		500 ->
			?assert(false)
	end.

invalid_and_valid_specifications_test() ->
	tiered_ring_buffer_sup:start_link(),
	{ok, Ref} = tiered_ring_buffer:new(invalid_and_valid_specifications_test),
	ok = tiered_ring_buffer:subscribe(Ref,  {empty}),
	ok = tiered_ring_buffer:subscribe(Ref,  {loop}),
	{invalid_specification} = tiered_ring_buffer:subscribe(Ref, {xxxx}).

% test helpers
process_loop(Ref) ->
	receive
		{subscribe, SubscriptionInfo} ->
			% io:format(user, "process ~p~n", [self()]),
			ok = tiered_ring_buffer:subscribe(Ref, SubscriptionInfo),
			process_loop(Ref);
		{die} ->
			ok
	end.