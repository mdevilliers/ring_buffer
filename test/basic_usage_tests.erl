-module (basic_usage_tests).

-include_lib("eunit/include/eunit.hrl").


new_buffer_multiple_loop_test() -> 
	% fills up and loops round
	tiered_ring_buffer_sup:start_link(),
	Entries = 20,
	{ok, Ref} = tiered_ring_buffer:new(new_buffer_multiple_loop_test, Entries),
	[ tiered_ring_buffer:add(Ref , N ) || N <- lists:seq(1, Entries * 2)],
	Results = tiered_ring_buffer:select_all(Ref),
 	?assertEqual(Entries, length(Results)),
	?assertEqual(Results, [40,39,38,37,36,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21]).

new_buffer_single_loop_test() -> 
	tiered_ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = tiered_ring_buffer:new(new_buffer_single_loop_test, Entries),
	[ tiered_ring_buffer:add(Ref , {N} ) || N <- lists:seq(1, Entries)],
	[{5},{4},{3},{2},{1}] = tiered_ring_buffer:select_all(Ref).

new_buffer_odd_value_loop_test() -> 
	tiered_ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = tiered_ring_buffer:new(new_buffer_odd_value_loop_test, Entries),
	[ tiered_ring_buffer:add(Ref , {N} ) || N <- lists:seq(1, Entries + 3)],
	[{8},{7},{6},{5},{4}] = tiered_ring_buffer:select_all(Ref).

new_buffer_semi_empty_test() -> 
	tiered_ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = tiered_ring_buffer:new(new_buffer_semi_empty_test, Entries),
	[ tiered_ring_buffer:add(Ref , {N} ) || N <- lists:seq(1, 3)],
	[{3},{2},{1},<<>>,<<>>] = tiered_ring_buffer:select_all(Ref).

new_buffer_select_count_test() ->
	tiered_ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = tiered_ring_buffer:new(new_buffer_select_count_test, Entries),
	[ tiered_ring_buffer:add(Ref , {N} ) || N <- lists:seq(1, 10)],
	io:format(user, "all : ~p~n", [tiered_ring_buffer:select_all(Ref)]),
%	[{10}] = tiered_ring_buffer:select(Ref, 1),
%	[{10},{9}] = tiered_ring_buffer:select(Ref, 2),
	[{10},{9},{8}] = tiered_ring_buffer:select(Ref, 3),
%	[{10},{9},{8},{7}] = tiered_ring_buffer:select(Ref, 4),
	[{10},{9},{8},{7},{6}] = tiered_ring_buffer:select(Ref, 5).

large_buffer_test() ->
	tiered_ring_buffer_sup:start_link(),
	Entries = 50000,
	{ok, Ref} = tiered_ring_buffer:new(large_buffer_test, Entries),
	[ tiered_ring_buffer:add(Ref , {N} ) || N <- lists:seq(1, Entries * 10)].

stop_and_clean_up_test() -> 
	tiered_ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = tiered_ring_buffer:new(stop_and_clean_up_test, Entries),
	tiered_ring_buffer:delete(Ref).


% TODO
% starting_multiple_ring_buffers_of_the_same_name_test()->
	% tiered_ring_buffer_sup:start_link(),
	% {ok, Ref} = tiered_ring_buffer:new(three_test, 5),
	% {ok, Ref} = tiered_ring_buffer:new(three_test, 5),
 % 	ok.