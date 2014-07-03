-module (subscription_tests).

-include_lib("eunit/include/eunit.hrl").

-export ([add_subscription_from_other_process/1]).

add_and_remove_subscription_test() ->
	tiered_ring_buffer_sup:start_link(),
	Entries = 2,
	Me = self(),
	
	{ok, Ref} = tiered_ring_buffer:new(add_subscription_test, Entries),
	{empty} = tiered_ring_buffer:list_subscriptions(Ref),
	
	ok = tiered_ring_buffer:subscribe(Ref, {full}),
	{ok,[{subscription, Me ,{full}}]} = tiered_ring_buffer:list_subscriptions(Ref),
	
	ok = tiered_ring_buffer:unsubscribe(Ref, {full}),
    {empty} = tiered_ring_buffer:list_subscriptions(Ref),

    ok = tiered_ring_buffer:subscribe(Ref, {empty}),
    ok = tiered_ring_buffer:subscribe(Ref, {full}),
    spawn(?MODULE, add_subscription_from_other_process, [Ref]),

	timer:sleep(10),

    {ok,Subscriptions} = tiered_ring_buffer:list_subscriptions(Ref),
    ?assertEqual(length(Subscriptions), 3),
	
	ok = tiered_ring_buffer:unsubscribe_all(Ref),

    % TODO : subscription from other process - I can't delete it - it should be dropped when the monitored process dies
	{ok,[{subscription,_,{xxxx}}]} = tiered_ring_buffer:list_subscriptions(Ref).

add_subscription_from_other_process(Ref) ->
	 ok = tiered_ring_buffer:subscribe(Ref, {xxxx}).

unsubscribe_all_when_empty_is_ok_test() ->
	tiered_ring_buffer_sup:start_link(),
	Entries = 2,	
	{ok, Ref} = tiered_ring_buffer:new(unsubscribe_all_when_empty_is_ok_test, Entries),
	ok = tiered_ring_buffer:unsubscribe_all(Ref),
	{empty} = tiered_ring_buffer:list_subscriptions(Ref),
	ok = tiered_ring_buffer:unsubscribe_all(Ref),
	{empty} = tiered_ring_buffer:list_subscriptions(Ref).


