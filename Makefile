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
	export PORT=4000 MIX_ENV=dev && ./_build/dev/rel/blockchain_api/bin/blockchain_api start

dev-foreground:
	export PORT=4000 MIX_ENV=dev && ./_build/dev/rel/blockchain_api/bin/blockchain_api foreground

dev-console:
	export PORT=4000 MIX_ENV=dev && ./_build/dev/rel/blockchain_api/bin/blockchain_api console

reset-dev-db:
	export PORT=4000 MIX_ENV=dev && $(MIX) ecto.reset

# Prod targets
release:
	export NO_ESCRIPT=1 MIX_ENV=prod && $(MIX) distillery.release --env=prod

reset-prod-db:
	export PORT=4001 MIX_ENV=prod && $(MIX) ecto.reset

prod-interactive:
	export PORT=4001 MIX_ENV=prod && iex -S mix phx.server

prod-start:
	export PORT=4001 MIX_ENV=prod && ./_build/prod/rel/blockchain_api/bin/blockchain_api start

prod-foreground:
	export PORT=4001 MIX_ENV=prod && ./_build/prod/rel/blockchain_api/bin/blockchain_api foreground

prod-console:
	export PORT=4001 MIX_ENV=prod && ./_build/prod/rel/blockchain_api/bin/blockchain_api console

# Test targets
test:
	export PORT=4002 MIX_ENV=test && $(MIX) test --trace

testrelease:
	export NO_ESCRIPT=1 MIX_ENV=test && $(MIX) distillery.release --env=test

test-start:
	export PORT=4002 MIX_ENV=test && ./_build/test/rel/blockchain_api/bin/blockchain_api start

test-console:
	export PORT=4002 MIX_ENV=test && ./_build/test/rel/blockchain_api/bin/blockchain_api console

reset-test-db:
	export PORT=4002 MIX_ENV=test && $(MIX) ecto.reset

ci:
	export PORT=4002 MIX_ENV=test NO_ESCRIPT=1 && $(MIX) local.hex --force && $(MIX) local.rebar --force && $(MIX) deps.get && $(MIX) test --trace
