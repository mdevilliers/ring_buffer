-module (basic_usage_tests).

-include_lib("eunit/include/eunit.hrl").


new_buffer_multiple_loop_test() -> 

	% fills up and loops round
	tiered_ring_buffer_sup:start_link(),

	Entries = 20,
	{ok, Ref} = tiered_ring_buffer:new(one_test, Entries),
	[ tiered_ring_buffer:add(Ref , N ) || N <- lists:seq(1, Entries * 2)],
	Results = tiered_ring_buffer:select(Ref),
	
 	io:format(user, "~p~n", [Results]),
 	?assertEqual(Entries, length(Results)),
 	ok.

new_buffer_single_loop_test() -> 
	% fills up
	tiered_ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = tiered_ring_buffer:new(two_test, Entries),
	[ tiered_ring_buffer:add(Ref , {N} ) || N <- lists:seq(1, Entries)],
	Results = tiered_ring_buffer:select(Ref),
 	io:format(user, "~p~n", [Results]),
 	?assertEqual(Entries, length(Results)),
 	ok.

new_buffer_odd_value_loop_test() -> 
	
	tiered_ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = tiered_ring_buffer:new(three_test, Entries),
	[ tiered_ring_buffer:add(Ref , {N} ) || N <- lists:seq(1, Entries + 3)],
	Results = tiered_ring_buffer:select(Ref),
 	io:format(user, "~p~n", [Results]),
 	?assertEqual(Entries, length(Results)),
 	ok.

range_test() ->
	Entries = 20,
	Position = 5,

	Range = lists:seq(0,Entries),
	{One,Two} = lists:split(Position , Range),
	Sequence = lists:flatten([Two|One]),
	io:format(user, "~p~n", [Sequence]).

% TODO
% starting_multiple_ring_buffers_of_the_same_name_test()->
	% tiered_ring_buffer_sup:start_link(),
	% {ok, Ref} = tiered_ring_buffer:new(three_test, 5),
	% {ok, Ref} = tiered_ring_buffer:new(three_test, 5),
 % 	ok.