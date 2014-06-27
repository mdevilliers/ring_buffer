

{ok, Ref} = tiered_ring_buffer:new(basic_test),
tiered_ring_buffer:subscribe(Ref, {writes:60} )

ok = tiered_ring_buffer:add(Ref, 1 ),
ok = tiered_ring_buffer:add(Ref, 1 ),
...
ok = tiered_ring_buffer:add(Ref, 1 ),



