#!/bin/bash
bin="/app/bin/server"


# Setup the database.
echo "running migrations"
$bin eval "Elixpeer.Release.migrate"

# # start the elixir application
# echo "starting application"
# exec "$bin"