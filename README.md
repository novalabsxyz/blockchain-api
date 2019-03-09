# BlockchainAPI

An API for the helium blockchain

## Local Installation

In order to run locally, a number of dependencies must be met.

(Note: These are required to build and run this node. Releases will be built in the future which require no external dependencies)

### Homebrew

For OSX, make sure you have [Homebrew](https://brew.sh/) installed. We'll use it to install the following dependencies

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

### Native Dependencies

```
$ brew install autoconf automake wget yasm gmp libtool cmake clang-format lcov doxygen
```

### Elixir
For OSX,
```
$ brew install elixir
```
For Ubuntu, default package manager is woefully out of date so follow [elixir-lang.org instructions](https://elixir-lang.org/install.html#unix-and-unix-like)
```
$ wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb
$ sudo apt-get update
$ sudo apt-get install esl-erlang
$ sudo apt-get install elixir
```

### Postgres

You'd need to install postgres server if you haven't already and configure it with a default postgres/postgres user/passwrod for now. (We'll change that on the production server as needed)

```
$ sudo apt install postgresql
$ sudo -u postgres psql postgres
$ sudo -u postgres createuser --superuser $USER
```


### Clone blockchain-api

Clone the `blockchain-api` project somewhere.

```
$ git clone git@github.com:helium/blockchain_api.git
```

### Fetch deps

`cd` into `blockchain-api` and use mix to fetch the erlang/elixir dependencies.

```
$ mix deps.get
```

### Build a release

Unless you're doing some development on the node, you'll want to build a `prod` release.

#### Building a prod release
`cd` into the `blockchain-api` project and then run:

```
$ make release
```

#### Building a dev release
`cd` into the `blockchain-api` project and then run:

```
$ make devrelease
```

Note: A devrelease is not connected to the seed nodes, you need to have a local blockchain running

#### Running Interactively (Prod)
Doing so will connect you to the seed nodes and boot the chain with the priv/genesis block

`cd` into the `blockchain-api` project and then run:

Remove existing data folder (if any). NOTE: This will wipe an existing chain if you had one before.

```rm -rf data```

Build clean

```make clean && make```

Reset Database to start fresh

```make reset-prod-db```

Start interactively

```make prod-start```


#### Running Interactively (Dev)
Doing so will NOT connect you to the seed nodes, you'll have to supply it manually on the interactive shell.

`cd` into the `blockchain-api` project and then run:

Remove existing data folder (if any)

```rm -rf data```

Build clean

```make clean && make```

Reset Database to start fresh

```make reset-dev-db```

Start interactively

```make dev-start```

#### Running Tests

`cd` into the `blockchain-api` project and run:

```
make clean && make reset-test-db && make test
```
