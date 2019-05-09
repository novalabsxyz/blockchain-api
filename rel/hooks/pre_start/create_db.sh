#!/usr/bin/env bash

echo "Running database creation"
bin/blockchain_api command Elixir.Release.Tasks create_db
echo "DB created successfully"
