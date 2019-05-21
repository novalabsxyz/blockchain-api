#===========
#Build Stage
#===========
FROM elixir:latest as build

# This would be exported down to the runtime container
ENV LD_LIBRARY_PATH /usr/local/lib
# Define Libsodium version
ENV LIBSODIUM_VERSION 1.0.16
# Define app name
ENV APP_NAME="blockchain_api"

# Install some tools
RUN \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install curl build-essential unzip locate flex bison libgmp-dev cmake doxygen locales tree

RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf
RUN locale-gen en_US.UTF-8

# Download & extract & make libsodium
# Move libsodium build
RUN \
    mkdir -p /tmpbuild/libsodium && \
    cd /tmpbuild/libsodium && \
    curl -L https://download.libsodium.org/libsodium/releases/libsodium-${LIBSODIUM_VERSION}.tar.gz -o libsodium-${LIBSODIUM_VERSION}.tar.gz && \
    tar xfvz libsodium-${LIBSODIUM_VERSION}.tar.gz && \
    cd /tmpbuild/libsodium/libsodium-${LIBSODIUM_VERSION}/ && \
    ./configure && \
    make && make check && \
    make install && \
    mv src/libsodium /usr/local/ && \
    rm -Rf /tmpbuild/

# Temporarily create a .ssh dir and put your private key file there to clone pvt repos
COPY --chown=root .ssh/id_rsa /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts
RUN echo "StrictHostKeyChecking no " >> /root/.ssh/config

WORKDIR /opt/app

# Copy only the required files
ADD ./lib ./lib
ADD ./priv ./priv
ADD ./cmd .
ADD ./Makefile .
ADD ./mix.exs .
ADD ./mix.lock .
ADD ./config/prod.exs ./config/prod.exs
ADD ./config/config.exs ./config/config.exs
ADD ./rebar3 .
ADD ./rel ./rel

# Check whether we have everything we need
RUN tree

# Env must be set at _build_ time for app to work correctly
ENV REPLACE_OS_VARS=true
ENV MIX_ENV=prod

# Docker build environments
ARG SEED_NODES
ARG SEED_NODE_DNS
ARG GOOGLE_MAPS_API_KEY
ARG ONESIGNAL_API_KEY
ARG ONESIGNAL_APP_ID
ARG SECRET_KEY_BASE
ARG PORT
ARG DATABASE_NAME
ARG DATABASE_USER
ARG DATABASE_PASS
ARG DATABASE_HOST
ARG APP_VSN
# Use docker build args to build the app which uses these as environment variables
ENV SEED_NODES=${SEED_NODES}
ENV SEED_NODE_DNS=${SEED_NODE_DNS}
ENV GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}
ENV ONESIGNAL_API_KEY=${ONESIGNAL_API_KEY}
ENV ONESIGNAL_APP_ID=${ONESIGNAL_APP_ID}
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}
ENV PORT=${PORT}
ENV DATABASE_NAME=${DATABASE_NAME}
ENV DATABASE_USER=${DATABASE_USER}
ENV DATABASE_PASS=${DATABASE_PASS}
ENV DATABASE_HOST=${DATABASE_HOST}

# Build the app release
RUN mix local.rebar --force && \
        mix local.hex --force && \
        mix deps.get && \
        make clean && \
        mkdir -p /opt/built && \
        make release && \
        cp _build/${MIX_ENV}/rel/${APP_NAME}/releases/${APP_VSN}/${APP_NAME}.tar.gz /opt/built && \
        cd /opt/built && \
        tar -xzf ${APP_NAME}.tar.gz && \
        rm ${APP_NAME}.tar.gz

#================
# Deployment Stage
#================
FROM elixir:latest

RUN apt-get update
RUN apt-get -y install locales tree

ARG APP_NAME

# Why the fuck do I have to do this again >:(
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf
RUN locale-gen en_US.UTF-8

ENV REPLACE_OS_VARS=true
ENV APP_NAME=${APP_NAME}
ENV LD_LIBRARY_PATH /usr/local/lib
ENV MIX_ENV prod

# Copy libsodium and stuff
COPY --from=build /usr/local .

# Move to the app directory
WORKDIR /opt/app

# Copy the built release
COPY --from=build /opt/built .

CMD trap 'exit' INT; /opt/app/bin/${APP_NAME} foreground
