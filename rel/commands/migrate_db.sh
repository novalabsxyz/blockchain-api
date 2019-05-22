#!/usr/bin/env bash

set +e

while true; do
  nodetool ping
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then
    echo "Application is up!"
    break
  fi
done

set -e

echo "Running migrations"
bin/blockchain_api command Elixir.BlockchainAPI.Release.Tasks migrate
echo "Migrations run successfully"
