# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :blockchain_api,
  ecto_repos: [BlockchainAPI.Repo]

# Configures the endpoint
config :blockchain_api, BlockchainAPIWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "OOLfw0Ez2rPqx6IOAsgbvj+5SxUhPuZ1zm6mHP0t2ETXk/8gT0guAres57j9LffB",
  render_errors: [view: BlockchainAPIWeb.ErrorView, format: "json", accepts: ~w(json)],
  pubsub: [name: BlockchainAPI.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger,
  backends: [
    :console,
    {LoggerFileBackend, :debug_log},
    {LoggerFileBackend, :error_log},
    {LoggerFileBackend, :info_log}
  ],
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, :console, level: :info

config :logger, :error_log,
  path: "log/blockchain_api/error.log",
  level: :error,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, :info_log,
  path: "log/blockchain_api/info.log",
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, :debug_log,
  path: "log/blockchain_api/debug.log",
  level: :debug,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# This is required for making cuttlefish and cli happy
System.put_env("NO_ESCRIPT", "1")
Code.compiler_options(ignore_module_conflict: true)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
