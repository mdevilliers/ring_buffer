-module (basic_usage_tests).

-export ([large_buffer/0]).

-include_lib("eunit/include/eunit.hrl").

basic_test() ->
	ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = ring_buffer:new(basic_test, Entries),
	ok = ring_buffer:add(Ref, 1 ),
	[1] = ring_buffer:select(Ref, 1),
	1 = ring_buffer:count(Ref),
    [1,<<>>,<<>>,<<>>,<<>>] = ring_buffer:select_all(Ref),
	ok = ring_buffer:add(Ref, 2 ),
	[2,1] = ring_buffer:select(Ref, 2),
	[2,1,<<>>,<<>>,<<>>] = ring_buffer:select_all(Ref),
	2 = ring_buffer:count(Ref),
	ok = ring_buffer:add(Ref, 3 ),
	[3,2,1] = ring_buffer:select(Ref, 3),
	[3,2,1,<<>>,<<>>] = ring_buffer:select_all(Ref),
	3 = ring_buffer:count(Ref),
	ok = ring_buffer:add(Ref, 4 ),
	[4,3,2,1] = ring_buffer:select(Ref, 4),
	[4,3,2,1,<<>>] = ring_buffer:select_all(Ref),
	4 = ring_buffer:count(Ref),
	ok = ring_buffer:add(Ref, 5 ),
	[5,4,3,2,1] = ring_buffer:select(Ref, 5),
	[5,4,3,2,1] = ring_buffer:select_all(Ref),
	5 = ring_buffer:count(Ref),
	ok = ring_buffer:add(Ref, 6 ),
	[6,5,4,3,2] = ring_buffer:select(Ref, 5),
	[6,5,4,3,2] = ring_buffer:select_all(Ref),
	5 = ring_buffer:count(Ref),
	ok = ring_buffer:add(Ref, 7 ),
	[7,6,5,4,3] = ring_buffer:select(Ref, 5),
	[7,6,5,4,3] = ring_buffer:select_all(Ref),
	5 = ring_buffer:count(Ref),
	ok = ring_buffer:add(Ref, 8 ),
	[8,7,6,5,4] = ring_buffer:select(Ref, 5),
	[8,7,6,5,4] = ring_buffer:select_all(Ref),
	5 = ring_buffer:count(Ref),
	ok = ring_buffer:add(Ref, 9 ),
	[9,8,7,6,5] = ring_buffer:select(Ref, 5),
	[9,8,7,6,5] = ring_buffer:select_all(Ref),
	ok = ring_buffer:add(Ref, 10 ),
	5 = ring_buffer:count(Ref),
	[10,9,8,7,6] = ring_buffer:select(Ref, 5),
	[10,9,8,7,6] = ring_buffer:select_all(Ref),
	ok = ring_buffer:add(Ref, 11 ),
	5 = ring_buffer:count(Ref),
	[11,10,9,8,7] = ring_buffer:select(Ref, 5),
	[11,10,9,8] = ring_buffer:select(Ref, 4),
	[11,10,9] = ring_buffer:select(Ref, 3),
	[11,10] = ring_buffer:select(Ref, 2),
	[11] = ring_buffer:select(Ref, 1).
	

stop_and_clean_up_test() -> 
	ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = ring_buffer:new(stop_and_clean_up_test, Entries),
	ring_buffer:delete(Ref).

invalid_size_test() ->
	ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = ring_buffer:new(invalid_count_test, Entries),
	{error, invalid_length} = ring_buffer:select(Ref, 1), % nothing written yet
	{error, invalid_length} = ring_buffer:select(Ref, 2), % nothing written yet
	{error, invalid_length} = ring_buffer:select(Ref, 3), % nothing written yet
	{error, invalid_length} = ring_buffer:select(Ref, 4), % nothing written yet
	{error, invalid_length} = ring_buffer:select(Ref, 5), % nothing written yet
	{error, invalid_length} = ring_buffer:select(Ref, -10), % negative number
	{error, invalid_length} = ring_buffer:select(Ref, 99). % bigger than initial size 

get_default_size_test() ->
	ring_buffer_sup:start_link(),
	{ok, Ref} = ring_buffer:new(invalid_count_test),
	512 = ring_buffer:size(Ref).

reset_state_test() ->
	ring_buffer_sup:start_link(),
	{ok, Ref} = ring_buffer:new(reset_state_test),
	ok = ring_buffer:add(Ref, 1 ),
	ok = ring_buffer:add(Ref, 1 ),
	ok = ring_buffer:add(Ref, 1 ),
	ok = ring_buffer:add(Ref, 1 ),
	ok = ring_buffer:add(Ref, 1 ),
	ok = ring_buffer:add(Ref, 1 ),
	6 = ring_buffer:count(Ref),
	ok =  ring_buffer:clear(Ref),
	ok = ring_buffer:add(Ref, 1 ),
	1 = ring_buffer:count(Ref),
	ok =  ring_buffer:clear(Ref),
	0 = ring_buffer:count(Ref).

% TODO
% starting_multiple_ring_buffers_of_the_same_name_test()->
	% ring_buffer_sup:start_link(),
	% {ok, Ref} = ring_buffer:new(three_test, 5),
	% {ok, Ref} = ring_buffer:new(three_test, 5),
 % 	ok.

large_test_test() ->
    {timeout, 30, fun() -> 
                 large_buffer()
          end }.

large_buffer() ->
	ring_buffer_sup:start_link(),
	Entries = 50000,
	{ok, Ref} = ring_buffer:new(large_buffer_test, Entries),
	[ ring_buffer:add(Ref , {N} ) || N <- lists:seq(1, Entries * 10)].
