-module (ring_buffer_app).

-behaviour(application).

%% Application callbacks
-export([start/0, start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start() -> application:start(ring_buffer).

start(_StartType, _StartArgs) ->
	ring_buffer_sup:start_link().

stop(_State) ->
    ok.
