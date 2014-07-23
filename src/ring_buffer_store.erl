-module (ring_buffer_store).
-include_lib("stdlib/include/ms_transform.hrl").

-export ([new/2,get/2,delete/1,insert/2]).

new(ets, Name) ->
  TableId = ets:new(Name, [ordered_set, named_table]),
  {?MODULE, ets, TableId};
new(dets, Name) ->
  {ok,TableId} = dets:open_file(Name, []),
  {?MODULE, dets, TableId}.

get(Position, {_, ets, TableId }) ->
  [{_, Value }] = ets:slot(TableId, Position),
  Value;
get(Position, {_, dets, TableId }) ->
  [Value] = dets:select(TableId, ets:fun2ms(fun({Pos,Value}) when  Pos =:= Position -> Value end)),
  Value.

delete({_, ets, TableId }) ->
  true = ets:delete(TableId);
delete({_, dets, TableId }) ->
  ok = dets:delete_all_objects(TableId),
  file:delete(TableId).

insert(Value,{_, ets, TableId }) ->
  ets:insert(TableId, Value);
insert(Value,{_, dets, TableId }) ->
  dets:insert(TableId, Value).