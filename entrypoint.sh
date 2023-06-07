#!/bin/bash
# Docker entrypoint script.

# Wait until Postgres is ready.
while ! pg_isready -q -h $PGHOST -p $PGPORT -U $PGUSER
do
  echo "$(date) - waiting for database to start"
  sleep 2
done

str=`date -Ins | md5sum`
name=${str:0:10}

# Create, migrate, and seed database if it doesn't exist.
if [[ -z `psql -Atqc "\\list $PGDATABASE"` ]]; then
  echo "Database $PGDATABASE does not exist. Creating..."
  createdb -E UTF8 $PGDATABASE -l en_US.UTF-8 -T template0
  mix ecto.setup
  mix run priv/repo/seeds.exs
  echo "Database $PGDATABASE created."
else
  mix ecto.migrate
fi

mix phx.swagger.generate
exec elixir --sname $name --cookie monster -S mix phx.server
