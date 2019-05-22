#!/usr/bin/env bash

echo "Create DB"
bin/blockchain_api command Elixir.BlockchainAPI.Release.Tasks createdb
echo "DB created successfully"
