#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PG_DATA_DIR="$DIR/../.pgdata"
PG_PORT=5433
PG_USER=postgres
DB_NAME=worker_management_db
PG_BIN="/opt/homebrew/opt/postgresql@15/bin"

if [ ! -d "$PG_BIN" ]; then
  if which initdb >/dev/null 2>&1; then
    PG_BIN="$(dirname "$(which initdb)")"
  elif [ -d "/Library/PostgreSQL/18/bin" ]; then
    PG_BIN="/Library/PostgreSQL/18/bin"
  fi
fi

echo "Using Postgres bin: $PG_BIN"

if [ ! -d "$PG_DATA_DIR" ]; then
  echo "Initializing PostgreSQL data directory at $PG_DATA_DIR..."
  "$PG_BIN/initdb" -D "$PG_DATA_DIR" -U "$PG_USER" --auth=trust
  echo "port = $PG_PORT" >> "$PG_DATA_DIR/postgresql.conf"
fi

if ! "$PG_BIN/pg_isready" -p "$PG_PORT" -h localhost >/dev/null 2>&1; then
  echo "Starting PostgreSQL on port $PG_PORT..."
  "$PG_BIN/pg_ctl" -D "$PG_DATA_DIR" -l "$DIR/../postgres.log" start
  sleep 2
fi

echo "Ensuring database $DB_NAME exists..."
"$PG_BIN/createdb" -U "$PG_USER" -h localhost -p "$PG_PORT" "$DB_NAME" 2>/dev/null || true

echo "PostgreSQL is running and database $DB_NAME is ready on port $PG_PORT!"
