.PHONY: all compile clean release devrelease test

MIX=$(shell which mix)

all: set_rebar set_hex deps compile

set_hex:
	mix local.hex --force

set_rebar:
	mix local.rebar rebar3 ./rebar3 --force

deps:
	mix deps.get

compile:
	$(MIX) compile

clean:
	$(MIX) clean

# Dev targets
devrelease:
	MIX_ENV=dev $(MIX) distillery.release --env=dev

dev-start:
	PORT=4000 MIX_ENV=dev ./_build/dev/rel/blockchain_api/bin/blockchain_api start

dev-foreground:
	PORT=4000 MIX_ENV=dev ./_build/dev/rel/blockchain_api/bin/blockchain_api foreground

dev-console:
	PORT=4000 MIX_ENV=dev ./_build/dev/rel/blockchain_api/bin/blockchain_api console

reset-dev-db:
	PORT=4000 MIX_ENV=dev $(MIX) ecto.reset

# Prod targets
release:
	NO_ESCRIPT=1 MIX_ENV=prod $(MIX) distillery.release --env=prod

reset-prod-db:
	PORT=4001 MIX_ENV=prod $(MIX) ecto.reset

prod-interactive:
	PORT=4001 MIX_ENV=prod iex -S mix phx.server

prod-start:
	PORT=4001 MIX_ENV=prod ./_build/prod/rel/blockchain_api/bin/blockchain_api start

prod-foreground:
	PORT=4001 MIX_ENV=prod ./_build/prod/rel/blockchain_api/bin/blockchain_api foreground

prod-console:
	PORT=4001 MIX_ENV=prod ./_build/prod/rel/blockchain_api/bin/blockchain_api console

# Test targets
test:
	PORT=4002 MIX_ENV=test $(MIX) test --trace

reset-test-db:
	PORT=4002 MIX_ENV=test $(MIX) ecto.reset
