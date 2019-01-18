.PHONY: all compile clean release devrelease

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

reset-prod-db:
	NO_ESCRIPT=1 PORT=4001 MIX_ENV=prod $(MIX) ecto.reset

reset-dev-db:
	NO_ESCRIPT=1 MIX_ENV=dev $(MIX) ecto.reset

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
	docker build -t blockchain-api .
	docker create -p 4001:4001 -v /root/.helium --name=blockchain-api blockchain-api

docker-start:
	docker start blockchain-api

docker-stop:
	docker stop blockchain-api

docker-genesis-onboard:
	docker exec -it blockchain-api sh -c "/bin/blockchain_api genesis onboard"

docker-shell:
	docker exec -it blockchain-api sh
