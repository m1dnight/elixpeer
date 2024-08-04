#!/bin/bash
bin="/app/bin/server"


# Setup the database.
$bin eval "Elixpeer.Release.migrate"

# start the elixir application
exec "$bin"