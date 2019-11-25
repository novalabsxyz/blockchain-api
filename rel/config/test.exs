use Mix.Config

port = String.to_integer(System.get_env("PORT") || "4002")

config :blockchain_api, BlockchainAPIWeb.Endpoint,
  http: [port: port],
  url: [host: System.get_env("HOSTNAME") || "localhost", port: port],
  server: true,
  root: ".",
  version: Application.spec(:blockchain_api, :vsn),
  check_origin: false,
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# Only debug statements for tests
config :logger, level: :debug

config :blockchain_api,
  env: Mix.env(),
  google_maps_secret: System.get_env("GOOGLE_MAPS_API_KEY"),
  notifier_client: BlockchainAPI.FakeNotifierClient

# Preset database configuration for tests
# Configure your database
config :blockchain_api, BlockchainAPI.Repo,
  username: "postgres",
  password: "postgres",
  database: "blockchain-api-test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  timeout: 120000,
  ownership_timeout: 120000,
  log: false

config :blockchain_api,
  env: Mix.env(),
  notifier_client: BlockchainAPI.FakeNotifierClient

# Don't connect dev to seed nodes
config :blockchain,
  seed_nodes: [],
  seed_node_dns: '',
  base_dir: String.to_charlist("/var/data/blockchain-api/test/")
