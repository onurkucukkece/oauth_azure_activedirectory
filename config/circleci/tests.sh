#!/bin/bash

export MIX_ENV="circle"
export PATH="$HOME/dependencies/erlang/bin:$HOME/dependencies/elixir/bin:$PATH"

elixir -v
mix test