

{ok, Ref} = tiered_ring_buffer:new(basic_test),

tiered_ring_buffer:subscribe(Ref, {writes, 60} )
tiered_ring_buffer:subscribe(Ref, {full} )
tiered_ring_buffer:subscribe(Ref, {empty} )


ok = tiered_ring_buffer:add(Ref, 1 ),
ok = tiered_ring_buffer:add(Ref, 1 ),
...
ok = tiered_ring_buffer:add(Ref, 1 ),

receive
	{ringbuffer, Ref, {full, 512, Messages}}	->
		body
	{ringbuffer, Ref, {writes, 60, Messages}}	-> % does this need a reference to get that state or are writes paused?
		body
	{ringbuffer, Ref, {empty}}	->
		body
end

tiered_ring_buffer:unsubscribe(Ref)
