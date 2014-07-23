-module (basic_usage_tests).

-export ([large_buffer/0]).

-include_lib("eunit/include/eunit.hrl").

basic_ets_test() -> do_basic(ets).
basic_dets_test() -> do_basic(dets).

do_basic(Impl) ->
	ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = ring_buffer:new(basic_test, Entries, Impl),
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
	[11] = ring_buffer:select(Ref, 1),
	ring_buffer:delete(Ref).

ets_stop_and_clean_up_test() -> do_stop_and_clean_up(ets).
dets_stop_and_clean_up_test() -> do_stop_and_clean_up(dets).
	
do_stop_and_clean_up(Impl) -> 
	ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = ring_buffer:new(stop_and_clean_up_test, Entries, Impl),
	ring_buffer:delete(Ref).

ets_invalid_size_test() -> do_invalid_size(ets). 
dets_invalid_size_test()-> do_invalid_size(dets).

do_invalid_size(Impl) ->
	ring_buffer_sup:start_link(),
	Entries = 5,
	{ok, Ref} = ring_buffer:new(invalid_count_test, Entries, Impl),
	{error, invalid_length} = ring_buffer:select(Ref, 1), % nothing written yet
	{error, invalid_length} = ring_buffer:select(Ref, 2), % nothing written yet
	{error, invalid_length} = ring_buffer:select(Ref, 3), % nothing written yet
	{error, invalid_length} = ring_buffer:select(Ref, 4), % nothing written yet
	{error, invalid_length} = ring_buffer:select(Ref, 5), % nothing written yet
	{error, invalid_length} = ring_buffer:select(Ref, -10), % negative number
	{error, invalid_length} = ring_buffer:select(Ref, 99), % bigger than initial size 
	ring_buffer:delete(Ref).

ets_get_default_size_test() -> do_get_default_size(ets). 
dets_get_default_size_test()-> do_get_default_size(dets).

do_get_default_size(Impl) ->
	ring_buffer_sup:start_link(),
	{ok, Ref} = ring_buffer:new(get_default_size_test, Impl),
	512 = ring_buffer:size(Ref),
	ring_buffer:delete(Ref).

ets_reset_state_test() -> do_reset_state_test(ets). 
dets_reset_state_test()-> do_reset_state_test(dets).

do_reset_state_test(Impl) ->
	ring_buffer_sup:start_link(),
	{ok, Ref} = ring_buffer:new(reset_state_test, Impl),
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
	0 = ring_buffer:count(Ref),
	ring_buffer:delete(Ref).

ets_starting_multiple_ring_buffers_of_the_same_name_test() -> do_starting_multiple_ring_buffers_of_the_same_name(ets). 
% dets_starting_multiple_ring_buffers_of_the_same_name_test()-> do_starting_multiple_ring_buffers_of_the_same_name(dets).

do_starting_multiple_ring_buffers_of_the_same_name(Impl)->
	ring_buffer_sup:start_link(),
	{ok, Ref} = ring_buffer:new(starting_multiple_ring_buffers_of_the_same_name_test, 5, Impl),
	{ok, Ref} = ring_buffer:new(starting_multiple_ring_buffers_of_the_same_name_test, 5, Impl),
	{ok, Ref} = ring_buffer:new(starting_multiple_ring_buffers_of_the_same_name_test, 5, Impl),
	{ok, Ref} = ring_buffer:new(starting_multiple_ring_buffers_of_the_same_name_test, 5, Impl),
	{ok, Ref} = ring_buffer:new(starting_multiple_ring_buffers_of_the_same_name_test, 5, Impl),
	{ok, Ref} = ring_buffer:find(starting_multiple_ring_buffers_of_the_same_name_test),
    ring_buffer:delete(Ref).

exists_on_non_existent_buffer_test() ->
	undefined = ring_buffer:find(does_not_exist).

large_test_test() ->
    {timeout, 30, fun() -> large_buffer() end }.

large_buffer() ->
	ring_buffer_sup:start_link(),
	Entries = 50000,
	{ok, Ref} = ring_buffer:new(large_buffer_test, Entries),
	[ ring_buffer:add(Ref , {N} ) || N <- lists:seq(1, Entries * 10)].
