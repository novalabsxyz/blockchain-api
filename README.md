# Helium Blockchain API

The Helium Blockchain API is a full blockchain node that exposes a JSON API which can be consumed by client applications like mobile applications or block explorers.

[![Build status](https://badge.buildkite.com/1c819cef9216a66d6b7132c8b085d36bb915f141d1fd3337e3.svg)](https://buildkite.com/helium/blockchain-api)

## Installation

In order to run a local instance of the API a number of dependencies must be met.

(Note: These are required to build and run this node. Releases will be built in the future which require no external dependencies)

### Homebrew

If using macOS make sure you have [Homebrew](https://brew.sh/) installed. We'll use it to install the following dependencies

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

### Native Dependencies

```
$ brew install autoconf automake wget yasm gmp libtool cmake clang-format lcov doxygen libsodium
```

### Elixir

For macOS:
```
$ brew install elixir
```

For Ubuntu/Debian, the default package manager is woefully out of date so follow [elixir-lang.org instructions](https://elixir-lang.org/install.html#unix-and-unix-like)
```
$ wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb
$ sudo apt-get update
$ sudo apt-get install esl-erlang
$ sudo apt-get install elixir
```

### PostgreSQL

Install PostgreSQL if you haven't already and configure it with a default postgres/postgres user/pasword for now.

For macOS:

```
$ brew install postgresql
$ initdb /usr/local/var/postgres
$ brew services start postgresql

```

For Ubuntu/Debian,
```
$ sudo apt install postgresql
$ sudo -u postgres psql postgres
$ sudo -u postgres createuser --superuser $USER
```

NOTE: please edit `config/prod.exs` with your database credentials, otherwise it is assumed environment variables of `DATABASE_USER`, `DATABASE_PASS`, `DATABASE_NAME`, and `DATABASE_HOST` are present.

### Clone blockchain-api

Clone this `blockchain-api` repo:

```
$ git clone https://github.com/helium/blockchain-api.git
```

### Fetch Elixir Dependencies

`cd` into `blockchain-api` and use mix to fetch the erlang/elixir dependencies.

```
$ mix deps.get
```

## Using the API

### Building a release

Unless you're doing some development and need debugging you'll want to build a `prod` release.

`cd` into the `blockchain-api` folder and then run:

```
$ make release
```

### Starting the API

Once the API has been built, you can start it by running:

```
$ make prod-start
```

This will connect the node to the main network and use the genesis block contained in the `priv/prod` folder.

You can check that the API is running by visiting `http://localhost:4001/` from a web browser. You should get an `ok` response.

NOTE: by default, the `config/prod.exs` configuration file assumes that the base directory is `/var/data/blockchain-api/prod` and that the API server should be running on either the `PORT` environment variable or port `4001`. Please edit the `port` and `base_dir` variables in `prod.exs` as desired for your configuration.

The API also expects an environment variable called `GOOGLE_MAPS_API_KEY` to be set, which is used to reverse lookup the hotspot location.

The API routes are [temporarily documented](https://documenter.getpostman.com/view/8776393/SVmsTzP6?version=latest#2755b1c5-065c-46d4-b020-f8c3282d381f) on Postman.

### Using the CLI

Now that everything is working as intended, we can run a couple of quick CLI commands. 

Firstly, check whether we are connected to the network and have a few peers:

```
$ _build/prod/rel/blockchain_api/bin/blockchain-api peer book -s
````

We can also check our block height:

```
$ _build/prod/rel/blockchain_api/bin/blockchain-api status height
````

Or run:

```
$ _build/prod/rel/blockchain_api/bin/blockchain-api
````

To get a list of commands.
