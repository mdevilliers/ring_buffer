-module (subscription_tests).

-include_lib("eunit/include/eunit.hrl").

-export ([process_loop/1]).

add_and_remove_subscription_test() ->
	tiered_ring_buffer_sup:start_link(),
	Entries = 2,
	Me = self(),
	
	% set uo and check if empty
	{ok, Ref} = tiered_ring_buffer:new(add_subscription_test, Entries),
	{empty} = tiered_ring_buffer:list_subscriptions(Ref),
	
	% add a subscription and unsubscribe - check empty
	ok = tiered_ring_buffer:subscribe(Ref, {full}),
	{ok,[{subscription, Me ,{full}}]} = tiered_ring_buffer:list_subscriptions(Ref),
	ok = tiered_ring_buffer:unsubscribe(Ref, {full}),
    {empty} = tiered_ring_buffer:list_subscriptions(Ref),


    % make some more subscriptions including one in aother process
    ok = tiered_ring_buffer:subscribe(Ref, {empty}),
    ok = tiered_ring_buffer:subscribe(Ref, {full}),
    Pid = spawn(?MODULE, process_loop , [Ref]),
    Pid ! {subscribe, {xxxx}},

	timer:sleep(100),
	
	% check all the subscriptions are all there
    {ok,Subscriptions} = tiered_ring_buffer:list_subscriptions(Ref),
    %io:format(user, "Subscriptions ~p~n", [Subscriptions]),
    ?assertEqual(length(Subscriptions), 3),
	
	% remove my subscriptions
	ok = tiered_ring_buffer:unsubscribe_all(Ref),

	% check there is one left
	{ok,[{subscription,_,{xxxx}}]} = tiered_ring_buffer:list_subscriptions(Ref),

	% kill it
	Pid ! {die},
	timer:sleep(100),

	% check there are no subscriptions left
	{empty} = tiered_ring_buffer:list_subscriptions(Ref).

process_loop(Ref) ->
	receive
		{subscribe, SubscriptionInfo} ->
			% io:format(user, "process ~p~n", [self()]),
			ok = tiered_ring_buffer:subscribe(Ref, SubscriptionInfo),
			process_loop(Ref);
		{die} ->
			io:format(user, "DIE process ~p~n", [self()]),
			ok
	end.

unsubscribe_all_when_empty_is_ok_test() ->
	tiered_ring_buffer_sup:start_link(),
	Entries = 2,	
	{ok, Ref} = tiered_ring_buffer:new(unsubscribe_all_when_empty_is_ok_test, Entries),
	ok = tiered_ring_buffer:unsubscribe_all(Ref),
	{empty} = tiered_ring_buffer:list_subscriptions(Ref),
	ok = tiered_ring_buffer:unsubscribe_all(Ref),
	{empty} = tiered_ring_buffer:list_subscriptions(Ref).


