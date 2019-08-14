use Mix.Config

port = String.to_integer(System.get_env("PORT") || "4002")
config :blockchain_api, BlockchainAPIWeb.Endpoint,
  http: [port: port],
  url: [host: (System.get_env("HOSTNAME") || "localhost"), port: port],
  server: true,
  root: ".",
  version: Application.spec(:blockchain_api, :vsn),
  check_origin: false,
  force_ssl: [hsts: true, rewrite_on: [:x_forwarded_proto]]

config :blockchain_api, env: Mix.env()

# Print only warnings and errors during test
config :logger, level: :debug

# Configure your database
config :blockchain_api, BlockchainAPI.Repo,
  username: "postgres",
  password: "postgres",
  database: "blockchain_api_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  timeout: 60000,
  log: false

config :blockchain_api, BlockchainAPIWeb.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE")
config :blockchain_api, google_maps_secret: System.get_env("GOOGLE_MAPS_API_KEY")

# Don't connect dev to seed nodes
config :blockchain,
  seed_nodes: [],
  seed_node_dns: ''
