#!/usr/bin/env bash

echo "Running migrations"
bin/blockchain_api command Elixir.Release.Tasks migrate
echo "Migrations run successfully"
