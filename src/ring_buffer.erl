-module(ring_buffer).

-export([	new/1,
			new/2,
			new/3, 
			add/2, 
			select_all/1,
			select/2, 
			delete/1,
			size/1,
			count/1,
			clear/1,
			find/2,
			subscribe/2,
			unsubscribe/2,
			unsubscribe_all/1,
			list_subscriptions/1
		]).

%% API
new(Name) when is_atom(Name) ->
	new(Name, ets).
new(Name, Length) when is_atom(Name), is_integer(Length) ->
   new(Name, Length, ets);
new(Name, ets) when is_atom(Name) ->
	new(Name, 512, ets);
new(Name, dets) when is_atom(Name) ->
	new(Name, 512, dets).
new(Name, Length, ets) when is_atom(Name),is_integer(Length) ->
	do_new(Name, Length, ets);
new(Name, Length, dets) when is_atom(Name),is_integer(Length) ->
	do_new(Name, Length, dets).

do_new(Name, Length, Type) ->
	case find(Name, Type) of
		undefined ->
			ring_buffer_sup:new_ring_buffer(Name, Length, Type);
		{ok, Pid} -> {ok, Pid}
	end.

add(Buffer, Data) when is_pid(Buffer)->
	gen_server:call(Buffer, {add, Data}).

select_all(Buffer) when is_pid(Buffer)->
	gen_server:call(Buffer, select_all).

select(Buffer, Count) when is_pid(Buffer), is_integer(Count)->
	gen_server:call(Buffer, {select, Count}).

delete(Buffer) when is_pid(Buffer)->
	gen_server:call(Buffer, delete).

size(Buffer) when is_pid(Buffer)->
	gen_server:call(Buffer, size).

count(Buffer) when is_pid(Buffer) ->
	gen_server:call(Buffer, count).

clear(Buffer) when is_pid(Buffer) ->
	gen_server:call(Buffer, clear).

find(Name, ets) when is_atom(Name) ->
	ring_buffer_store:find(Name, ets);
find(Name, dets) when is_atom(Name) ->
	ring_buffer_store:find(Name, dets).

subscribe(Buffer, Spec) when is_pid(Buffer) ->
	gen_server:call(Buffer, {subscribe, self(), Spec}).
unsubscribe(Buffer, Spec) when is_pid(Buffer) ->
	gen_server:call(Buffer, {unsubscribe, self(), Spec}).
unsubscribe_all(Buffer) when is_pid(Buffer) ->
	gen_server:call(Buffer, {unsubscribe_all, self()}).
list_subscriptions(Buffer) when is_pid(Buffer) ->
	gen_server:call(Buffer, {list_subscriptions}).