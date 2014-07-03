-module (basic_usage_tests).

-include_lib("eunit/include/eunit.hrl").

basic_test() ->
	tiered_ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = tiered_ring_buffer:new(basic_test, Entries),
	ok = tiered_ring_buffer:add(Ref, 1 ),
	[1] = tiered_ring_buffer:select(Ref, 1),
	1 = tiered_ring_buffer:count(Ref),
    [1,<<>>,<<>>,<<>>,<<>>] = tiered_ring_buffer:select_all(Ref),
	ok = tiered_ring_buffer:add(Ref, 2 ),
	[2,1] = tiered_ring_buffer:select(Ref, 2),
	[2,1,<<>>,<<>>,<<>>] = tiered_ring_buffer:select_all(Ref),
	2 = tiered_ring_buffer:count(Ref),
	ok = tiered_ring_buffer:add(Ref, 3 ),
	[3,2,1] = tiered_ring_buffer:select(Ref, 3),
	[3,2,1,<<>>,<<>>] = tiered_ring_buffer:select_all(Ref),
	3 = tiered_ring_buffer:count(Ref),
	ok = tiered_ring_buffer:add(Ref, 4 ),
	[4,3,2,1] = tiered_ring_buffer:select(Ref, 4),
	[4,3,2,1,<<>>] = tiered_ring_buffer:select_all(Ref),
	4 = tiered_ring_buffer:count(Ref),
	ok = tiered_ring_buffer:add(Ref, 5 ),
	[5,4,3,2,1] = tiered_ring_buffer:select(Ref, 5),
	[5,4,3,2,1] = tiered_ring_buffer:select_all(Ref),
	5 = tiered_ring_buffer:count(Ref),
	ok = tiered_ring_buffer:add(Ref, 6 ),
	[6,5,4,3,2] = tiered_ring_buffer:select(Ref, 5),
	[6,5,4,3,2] = tiered_ring_buffer:select_all(Ref),
	5 = tiered_ring_buffer:count(Ref),
	ok = tiered_ring_buffer:add(Ref, 7 ),
	[7,6,5,4,3] = tiered_ring_buffer:select(Ref, 5),
	[7,6,5,4,3] = tiered_ring_buffer:select_all(Ref),
	5 = tiered_ring_buffer:count(Ref),
	ok = tiered_ring_buffer:add(Ref, 8 ),
	[8,7,6,5,4] = tiered_ring_buffer:select(Ref, 5),
	[8,7,6,5,4] = tiered_ring_buffer:select_all(Ref),
	5 = tiered_ring_buffer:count(Ref),
	ok = tiered_ring_buffer:add(Ref, 9 ),
	[9,8,7,6,5] = tiered_ring_buffer:select(Ref, 5),
	[9,8,7,6,5] = tiered_ring_buffer:select_all(Ref),
	ok = tiered_ring_buffer:add(Ref, 10 ),
	5 = tiered_ring_buffer:count(Ref),
	[10,9,8,7,6] = tiered_ring_buffer:select(Ref, 5),
	[10,9,8,7,6] = tiered_ring_buffer:select_all(Ref),
	ok = tiered_ring_buffer:add(Ref, 11 ),
	5 = tiered_ring_buffer:count(Ref),
	[11,10,9,8,7] = tiered_ring_buffer:select(Ref, 5),
	[11,10,9,8] = tiered_ring_buffer:select(Ref, 4),
	[11,10,9] = tiered_ring_buffer:select(Ref, 3),
	[11,10] = tiered_ring_buffer:select(Ref, 2),
	[11] = tiered_ring_buffer:select(Ref, 1).
	

stop_and_clean_up_test() -> 
	tiered_ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = tiered_ring_buffer:new(stop_and_clean_up_test, Entries),
	tiered_ring_buffer:delete(Ref).

invalid_size_test() ->
	tiered_ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = tiered_ring_buffer:new(invalid_count_test, Entries),
	{error, invalid_length} = tiered_ring_buffer:select(Ref, 1), % nothing written yet
	{error, invalid_length} = tiered_ring_buffer:select(Ref, 2), % nothing written yet
	{error, invalid_length} = tiered_ring_buffer:select(Ref, 3), % nothing written yet
	{error, invalid_length} = tiered_ring_buffer:select(Ref, 4), % nothing written yet
	{error, invalid_length} = tiered_ring_buffer:select(Ref, 5), % nothing written yet
	{error, invalid_length} = tiered_ring_buffer:select(Ref, -10), % negative number
	{error, invalid_length} = tiered_ring_buffer:select(Ref, 99). % bigger than initial size 

get_default_size_test() ->
	tiered_ring_buffer_sup:start_link(),
	{ok, Ref} = tiered_ring_buffer:new(invalid_count_test),
	512 = tiered_ring_buffer:size(Ref).

reset_state_test() ->
	tiered_ring_buffer_sup:start_link(),
	{ok, Ref} = tiered_ring_buffer:new(reset_state_test),
	ok = tiered_ring_buffer:add(Ref, 1 ),
	ok = tiered_ring_buffer:add(Ref, 1 ),
	ok = tiered_ring_buffer:add(Ref, 1 ),
	ok = tiered_ring_buffer:add(Ref, 1 ),
	ok = tiered_ring_buffer:add(Ref, 1 ),
	ok = tiered_ring_buffer:add(Ref, 1 ),
	6 = tiered_ring_buffer:count(Ref),
	ok =  tiered_ring_buffer:clear(Ref),
	ok = tiered_ring_buffer:add(Ref, 1 ),
	1 = tiered_ring_buffer:count(Ref),
	ok =  tiered_ring_buffer:clear(Ref),
	0 = tiered_ring_buffer:count(Ref).

% TODO
% starting_multiple_ring_buffers_of_the_same_name_test()->
	% tiered_ring_buffer_sup:start_link(),
	% {ok, Ref} = tiered_ring_buffer:new(three_test, 5),
	% {ok, Ref} = tiered_ring_buffer:new(three_test, 5),
 % 	ok.

large_buffer_test() ->
	tiered_ring_buffer_sup:start_link(),
	Entries = 50000,
	{ok, Ref} = tiered_ring_buffer:new(large_buffer_test, Entries),
	[ tiered_ring_buffer:add(Ref , {N} ) || N <- lists:seq(1, Entries * 10)].
