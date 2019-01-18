use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :blockchain_api, BlockchainAPIWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :blockchain_api, BlockchainAPI.Repo,
  username: "postgres",
  password: "postgres",
  database: "blockchain_api_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
