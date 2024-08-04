#!/bin/bash
bin="/app/elixpeer/bin/elixpeer"


# Setup the database.
$bin eval "Elixpeer.Release.migrate"

# start the elixir application
exec "$bin" "start" 