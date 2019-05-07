#!/bin/sh

set -e

# Wait for Postgres to become available.
until psql -h db -U "postgres" -c '\q' 2>/dev/null; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

echo "\nPostgres is available: continuing with database setup..."

# Database setup
make reset-prod-db
# Start app in foreground
make prod-foreground
