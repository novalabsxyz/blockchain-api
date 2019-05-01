#============
# Build Stage
#============
FROM elixir:latest as builder

ENV LD_LIBRARY_PATH /usr/local/lib
# Define Libsodium version
ENV LIBSODIUM_VERSION 1.0.16

# Install some tools: gcc build tools, unzip, etc
RUN \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install curl build-essential unzip locate flex bison libgmp-dev cmake doxygen

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

# For getting access to private repos (temporary)
# Create a .ssh folder in the app directory and copy your private key there
COPY --chown=root .ssh/id_rsa /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts
RUN echo "StrictHostKeyChecking no " >> /root/.ssh/config

# Application name
ARG APP_NAME
# Application version
ARG APP_VSN
# Prod environment
ARG MIX_ENV=prod

ENV APP_NAME=${APP_NAME} \
    APP_VSN=${APP_VSN} \
    MIX_ENV=${MIX_ENV}

# Set work directory
WORKDIR /opt/blockchain_api

# COPY APP src code
COPY . .

RUN mix local.rebar --force \
    && mix local.hex --force \
    && mix deps.get \
    && make clean \
    && make release

RUN \
  mkdir -p /opt/built && \
  make release && \
  cp _build/${MIX_ENV}/rel/${APP_NAME}/releases/${APP_VSN}/${APP_NAME}.tar.gz /opt/built && \
  cd /opt/built && \
  tar -xzf ${APP_NAME}.tar.gz && \
  rm ${APP_NAME}.tar.gz

#=================
# Deployment Stage
#=================
FROM elixir:latest
ARG APP_NAME

RUN apt-get update

ENV REPLACE_OS_VARS=true \
    APP_NAME=${APP_NAME}

WORKDIR /opt/blockchain_api

COPY --from=builder /opt/built .

CMD trap 'exit' INT; /opt/blockchain_api/bin/${APP_NAME} foreground
