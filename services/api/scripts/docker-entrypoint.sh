#!/bin/sh
# Made by Dr Ali — run pending migrations then start the API.
set -e
cd /app
if [ -f dist/database/data-source.js ]; then
  echo "Running TypeORM migrations…"
  # Managed Postgres (Render) needs TLS when DATABASE_SSL is unset but host is *.render.com
  case "${DATABASE_URL:-}" in
    *render.com*|*amazonaws.com*)
      export DATABASE_SSL="${DATABASE_SSL:-true}"
      ;;
  esac
  node ./node_modules/typeorm/cli.js migration:run -d dist/database/data-source.js || {
    echo "Migration failed — refusing to start with schema mismatch"
    exit 1
  }
fi
exec node dist/main.js
