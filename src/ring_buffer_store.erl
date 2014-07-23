-module (ring_buffer_store).

-export ([new/2,get/2,delete/1,insert/2]).

% ets implementation
new(ets, Name) ->
  TableId = ets:new(Name, [ordered_set, named_table]),
  {?MODULE, ets, TableId}.

get( Position, {_, ets, TableId }) ->
  [{_, Value }] = ets:slot(TableId, Position),
  Value.

delete({_, ets, TableId }) ->
  true = ets:delete(TableId).

insert(Value,{_, ets, TableId }) ->
  ets:insert(TableId, Value).