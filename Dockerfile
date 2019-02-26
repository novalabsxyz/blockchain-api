#==========================================================
# Build Stage
#==========================================================
FROM elixir:latest as build
RUN apt-get update && apt-get install -y cmake doxygen

#==========================================================
# Install core deps
#==========================================================
WORKDIR /tmp
ENV LD_LIBRARY_PATH /usr/local/lib
RUN apt-get update
RUN apt-get install -y flex bison libgmp-dev cmake libsodium-dev
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
# Switch to app directory
#==========================================================
WORKDIR /opt/blockchain_api

#==========================================================
# Copy everything
#==========================================================
COPY . .

#==========================================================
# Build Release
#==========================================================
RUN rm -Rf _build \
    && rm -Rf deps \
    && mix local.rebar --force \
    && mix local.hex --force \
    && mix deps.get \
    && make release

#==========================================================
# Extract Release archive to /opt/export for copying in next stage
#==========================================================
RUN APP_NAME="blockchain_api"  \
    && RELEASE_DIR=`ls -d _build/prod/rel/$APP_NAME/releases/*/` \
    && mkdir /opt/export \
    && tar -xf "$RELEASE_DIR/$APP_NAME.tar.gz" -C /opt/export

#==========================================================
# Deployment Stage
#==========================================================
FROM elixir:latest

COPY --from=build /opt/export/ .
COPY --from=build /opt/blockchain_api/cmd .

EXPOSE 4001
ENV REPLACE_OS_VARS=true NO_ESCRIPT=1 PORT=4001 MIX_ENV=prod

ENTRYPOINT ["/bin/blockchain_api"]
CMD ["foreground"]
