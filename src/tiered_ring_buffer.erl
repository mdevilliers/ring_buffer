-module(tiered_ring_buffer).

-export([	new/1,
			new/2, 
			add/2, 
			select_all/1,
			select/2, 
			range/3,
			delete/1,
			size/1,
			count/1,
			clear/1
		]).

%% API
new(Name) when is_atom(Name) ->
	new(Name, 512).
new(Name, Length) when is_integer(Length), is_atom(Name) ->
	tiered_ring_buffer_sup:new_ring_buffer(Name, Length).

add(Buffer, Data) ->
	gen_server:call(Buffer, {add, Data}).

select_all(Buffer) ->
	gen_server:call(Buffer, select_all).

select(Buffer, Count) ->
	gen_server:call(Buffer, {select, Count}).

range(Buffer, From, Count) ->
	gen_server:call(Buffer, {range, From, Count}).

delete(Buffer) ->
	gen_server:call(Buffer, delete).

size(Buffer) ->
	gen_server:call(Buffer, size).

count(Buffer) ->
	gen_server:call(Buffer, count).

clear(Buffer) ->
	gen_server:call(Buffer, clear).
