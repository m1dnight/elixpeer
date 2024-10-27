#!/bin/bash
bin="/app/bin/server"


# Setup the database.
echo "running migrationss"
/app/bin/elixpeer eval "Elixpeer.Release.migrate"
echo "done"

# start the elixir application
echo "starting application"
exec "$bin"