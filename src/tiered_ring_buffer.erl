-module(tiered_ring_buffer).

-export([	new/1,
			new/2, 
			add/3, 
			add/2, 
			select/2, 
			select/1
		]).

%% API

new(Name) when is_atom(Name) ->
	new(Name, 512).
new(Name, Length) when is_integer(Length), is_atom(Name) ->
	tiered_ring_buffer_sup:new_ring_buffer(Name, Length).

add(Buffer, Data) ->
	add(Buffer,Data, undefined).
add(Buffer, Data, _EvictionFun) ->
	gen_server:call(Buffer, {add, Data}).


% http://stackoverflow.com/questions/3723064/sorting-erlang-records-in-a-list
select(Buffer) ->
	gen_server:call(Buffer, {select}).
select(Buffer, Count) ->
	gen_server:call(Buffer, {select, Count}).
%% Internals
