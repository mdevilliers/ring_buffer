-module(tiered_ring_buffer).

-export([	new/1,
			new/2, 
			add/2, 
			select_all/1,
			select/2, 
			delete/1,
			size/1,
			count/1,
			clear/1,
			subscribe/2,
			unsubscribe/2,
			unsubscribe_all/1,
			list_subscriptions/1
		]).

%% API
new(Name) when is_atom(Name) ->
	new(Name, 512).
new(Name, Length) when is_atom(Name),is_integer(Length) ->
	tiered_ring_buffer_sup:new_ring_buffer(Name, Length).

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

subscribe(Buffer, Spec) when is_pid(Buffer) ->
	gen_server:call(Buffer, {subscribe, self(), Spec}).
unsubscribe(Buffer, Spec) when is_pid(Buffer) ->
	gen_server:call(Buffer, {unsubscribe, self(), Spec}).
unsubscribe_all(Buffer) when is_pid(Buffer) ->
	gen_server:call(Buffer, {unsubscribe_all, self()}).
list_subscriptions(Buffer) when is_pid(Buffer) ->
	gen_server:call(Buffer, {list_subscriptions}).