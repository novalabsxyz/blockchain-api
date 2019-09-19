#==========================================================
# Build Stage
#==========================================================
ARG ELIXIR_VERSION=1.8.2
FROM elixir:${ELIXIR_VERSION} as build

#==========================================================
# Use /opt as a typical convention
#==========================================================
WORKDIR /opt/app

#==========================================================
# Build requirements arguments
#==========================================================
# The name of your application/release (required)
ARG APP_NAME
# The version of the application we are building (required)
ARG APP_VSN
# The environment to build with
ARG MIX_ENV

#==========================================================
# Set ENV using build args
#==========================================================
ENV APP_NAME=${APP_NAME} \
    APP_VSN=${APP_VSN} \
    MIX_ENV=${MIX_ENV} \
    REPLACE_OS_VARS=true

#==========================================================
# Install core deps
#==========================================================
ENV LD_LIBRARY_PATH /usr/local/lib
RUN apt-get update
RUN apt-get install -y curl locales autoconf automake libtool flex bison libgmp-dev cmake build-essential libssl-dev
# Set the locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN git clone -b stable https://github.com/jedisct1/libsodium.git
RUN cd libsodium && ./configure --prefix=/usr && make check && make install && cd ..

#==========================================================
# Support private repos (for now)
#==========================================================
COPY --chown=root .ssh/id_rsa /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts
RUN echo "StrictHostKeyChecking no " >> /root/.ssh/config

#==========================================================
# Install build tools
#==========================================================
RUN mix local.rebar --force && mix local.hex --force

#==========================================================
# Copy only required files
#==========================================================
COPY mix.exs .
COPY mix.lock .
COPY config/ config/
COPY lib/ lib/
COPY rel/ rel/
COPY priv/ priv/

#==========================================================
# Build Release
#==========================================================
RUN mix do deps.get, deps.compile, compile, distillery.release --verbose

#==========================================================
# Start
#==========================================================
CMD trap 'exit' INT; _build/${MIX_ENV}/rel/${APP_NAME}/bin/${APP_NAME} foreground
