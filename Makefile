.PHONY: all compile clean release devrelease test

MIX=$(shell which mix)

all: set_rebar deps compile

set_rebar:
	mix local.rebar rebar3 ./rebar3 --force

deps:
	mix deps.get

compile:
	NO_ESCRIPT=1 $(MIX) compile

clean:
	$(MIX) clean

test:
	NO_ESCRIPT=1 PORT=4002 MIX_ENV=test $(MIX) test --trace

reset-prod-db:
	NO_ESCRIPT=1 PORT=4001 MIX_ENV=prod $(MIX) ecto.reset

reset-dev-db:
	NO_ESCRIPT=1 PORT=4000 MIX_ENV=dev $(MIX) ecto.reset

reset-test-db:
	NO_ESCRIPT=1 PORT=4002 MIX_ENV=test $(MIX) ecto.reset

prod-interactive:
	NO_ESCRIPT=1 PORT=4001 MIX_ENV=prod iex -S mix phx.server

dev-console:
	NO_ESCRIPT=1 PORT=4000 MIX_ENV=dev ./_build/dev/rel/blockchain_api/bin/blockchain_api console

prod-start:
	NO_ESCRIPT=1 PORT=4001 MIX_ENV=prod ./_build/prod/rel/blockchain_api/bin/blockchain_api start

prod-foreground:
	NO_ESCRIPT=1 PORT=4001 MIX_ENV=prod ./_build/prod/rel/blockchain_api/bin/blockchain_api foreground

prod-console:
	NO_ESCRIPT=1 PORT=4001 MIX_ENV=prod ./_build/prod/rel/blockchain_api/bin/blockchain_api console

dev-start:
	NO_ESCRIPT=1 MIX_ENV=dev iex -S mix phx.server

release:
	NO_ESCRIPT=1 MIX_ENV=prod $(MIX) do release.clean, release

devrelease:
	NO_ESCRIPT=1 MIX_ENV=dev $(MIX) do release.clean, release

deployable: release
	@rm -rf latest
	@mkdir latest
	@cd _build/prod/rel && tar -czf blockchain_api-$(NODE_OS).tgz blockchain_api
	@mv _build/prod/rel/blockchain_api-$(NODE_OS).tgz latest/

docker-build:
	docker build -t blockchain_api .
	docker create -p 4001:4001 -v /root/.helium --name=blockchain_api blockchain_api

docker-start:
	docker start blockchain_api

docker-stop:
	docker stop blockchain_api

docker-genesis-onboard:
	docker exec -it blockchain_api sh -c "/bin/blockchain_api genesis onboard"

docker-shell:
	docker exec -it blockchain_api sh
