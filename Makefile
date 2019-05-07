.PHONY: all compile clean release devrelease test

MIX=$(shell which mix)
APP_NAME ?= `grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`
APP_VSN ?= `grep 'version:' mix.exs | cut -d '"' -f2`

all: set_rebar deps compile

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
	MIX_ENV=dev $(MIX) do release.clean, release --env=dev

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
	NO_ESCRIPT=1 MIX_ENV=prod $(MIX) do release.clean, release --env=prod

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

# Docker commands
docker-build:
	docker build \
		--build-arg APP_NAME=${APP_NAME} \
		--build-arg MIX_ENV=${MIX_ENV} \
		--build-arg SEED_NODES=${SEED_NODES} \
		--build-arg SEED_NODE_DNS=${SEED_NODE_DNS} \
		--build-arg GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY} \
		--build-arg ONESIGNAL_API_KEY=${ONESIGNAL_API_KEY} \
		--build-arg ONESIGNAL_APP_ID=${ONESIGNAL_APP_ID} \
		--build-arg SECRET_KEY_BASE=${SECRET_KEY_BASE} \
		--build-arg PORT=${PORT} \
		--build-arg DATBASE_NAME=${DATABASE_NAME} \
		--build-arg DATABASE_USER=${DATABASE_USER} \
		--build-arg DATABASE_PASS=${DATABASE_PASS} \
		--build-arg DATABASE_HOST=${DATABASE_HOST} \
        --build-arg APP_VSN=$(APP_VSN) \
        -t $(APP_NAME):$(APP_VSN)-$(BUILD) \
        -t $(APP_NAME):latest .

docker-run:
	docker run --env-file config/docker.env \
		--expose 4001 -p 4001:4001 \
		--rm -it $(APP_NAME):latest
