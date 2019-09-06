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
	export MIX_ENV=dev && $(MIX) distillery.release --env=dev

dev-start:
	./_build/dev/rel/blockchain_api/bin/blockchain_api start

dev-foreground:
	./_build/dev/rel/blockchain_api/bin/blockchain_api foreground

dev-console:
	./_build/dev/rel/blockchain_api/bin/blockchain_api console

reset-dev-db:
	MIX_ENV=dev && $(MIX) ecto.reset

# Prod targets
release:
	export NO_ESCRIPT=1 MIX_ENV=prod && $(MIX) distillery.release --env=prod

reset-prod-db:
	MIX_ENV=prod && $(MIX) ecto.reset

prod-interactive:
	iex -S mix phx.server

prod-start:
	./_build/prod/rel/blockchain_api/bin/blockchain_api start

prod-foreground:
	./_build/prod/rel/blockchain_api/bin/blockchain_api foreground

prod-console:
	./_build/prod/rel/blockchain_api/bin/blockchain_api console

# Test targets
test:
	MIX_ENV=test && $(MIX) test --trace

testrelease:
	export NO_ESCRIPT=1 MIX_ENV=test && $(MIX) distillery.release --env=test

test-start:
	./_build/test/rel/blockchain_api/bin/blockchain_api start

test-console:
	./_build/test/rel/blockchain_api/bin/blockchain_api console

reset-test-db:
	MIX_ENV=test && $(MIX) ecto.reset

ci:
	export PORT=4002 MIX_ENV=test NO_ESCRIPT=1 && $(MIX) local.hex --force && $(MIX) local.rebar --force && $(MIX) deps.get && $(MIX) test --trace
