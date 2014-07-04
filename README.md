ring-buffer
-----------

Implemetation of an ring buffer in erlang using ets tables as a backing store. An interesting property is being able to subscribe to various events.


Setting up a ring buffer, adding a few messages and getting alerted when ring buffer is full


```
ring_buffer_sup:start_link(),
Subscription = {loop},
RingBufferName = example,
Entries = 2,	
{ok, Ref} = ring_buffer:new( RingBufferName, Entries),

ok = ring_buffer:subscribe(Ref, Subscription),

% add some entries
ok = ring_buffer:add(Ref, 1 ),
ok = ring_buffer:add(Ref, 1 ),

receive
	{RingBufferName, Ref, Subscription} ->
		?assert(true),
	after
	500 ->
		?assert(false)
end.
```