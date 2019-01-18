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
  render_errors: [view: BlockchainAPIWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: BlockchainAPI.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
