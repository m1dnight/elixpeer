#!/bin/bash

set -e
# ssh -L 0.0.0.0:5433:0.0.0.0:5432 administrator@torrents.localdomain -N -v -v

# local to remote
# SOURCE=postgres://postgres:postgres@localhost:5432/elixpeer
# TARGET=postgres://postgres:postgres@localhost:5433/elixpeer
# TARGET_PSQL=postgres://postgres:postgres@localhost:5433/postgres

# remote to local
SOURCE=postgres://postgres:postgres@localhost:5430/elixpeer
TARGET=postgres://postgres:postgres@localhost:5432/elixpeer
TARGET_PSQL=postgres://postgres:postgres@localhost:5432/postgres

DB_NAME=elixpeer

pg_dumpall -d "$SOURCE" \
  -l $DB_NAME \
  --quote-all-identifiers \
  --roles-only \
  --file=roles.sql

sed -i -E \
-e '/CREATE ROLE "postgres";/d' \
-e '/ALTER ROLE "postgres"/d' \
-e 's/(NO)*SUPERUSER//g' \
-e 's/(NO)*REPLICATION//g' \
-e 's/(NO)*BYPASSRLS//g' \
-e 's/GRANTED BY "[^"]*"//g' \
roles.sql;


pg_dump -d "$SOURCE" \
  --format=plain \
  --quote-all-identifiers \
  --no-tablespaces \
  --no-owner \
  --no-privileges \
  --file=dump.sql;

# psql $SOURCE -c "ALTER EXTENSION timescaledb UPDATE TO '2.16.0';"
# psql $TARGET -c "ALTER EXTENSION timescaledb UPDATE TO '2.16.1';"

psql $TARGET_PSQL -c "drop database if exists $DB_NAME;";
psql $TARGET_PSQL -c "create database $DB_NAME;";


# psql $TARGET $DB_NAME -c "ALTER EXTENSION timescaledb UPDATE TO '2.16.1';"
psql $SOURCE $DB_NAME -c "SELECT extversion FROM pg_extension WHERE extname = 'timescaledb';"
psql $TARGET $DB_NAME -c "SELECT extversion FROM pg_extension WHERE extname = 'timescaledb';"

psql $TARGET -v ON_ERROR_STOP=1 --echo-errors \
    -f roles.sql \
    -c "SELECT timescaledb_pre_restore();" \
    -f dump.sql

psql $TARGET -v ON_ERROR_STOP=1 --echo-errors \
    -c "SELECT timescaledb_post_restore();"