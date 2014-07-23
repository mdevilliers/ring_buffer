ring-buffer
-----------

[![Build Status](https://travis-ci.org/mdevilliers/ring_buffer.svg?branch=master)](https://travis-ci.org/mdevilliers/ring_buffer)

Implemetation of an ring buffer in erlang using ets tables as a backing store. An interesting property is being able to subscribe to various events.

Examples
--------

Create an instance, adding a few messages and getting alerted when ring buffer is full

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

Or a notice every n messages

```
ring_buffer_sup:start_link(),

Subscription = {every, 5},
RingBufferName = example,
Entries = 10,	
{ok, Ref} = ring_buffer:new( RingBufferName, Entries),

ok = ring_buffer:subscribe(Ref, Subscription),

% add some entries
ok = ring_buffer:add(Ref, 1 ),
ok = ring_buffer:add(Ref, 2 ),
ok = ring_buffer:add(Ref, 3 ),
ok = ring_buffer:add(Ref, 4 ),
ok = ring_buffer:add(Ref, 5 ),

receive
	{RingBufferName, Ref, Subscription, [5,4,3,2,1]} ->
		?assert(true),
	after
	500 ->
		?assert(false)
end.

```