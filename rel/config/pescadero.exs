use Mix.Config

port = String.to_integer(System.get_env("PORT") || "4002")

config :blockchain_api, BlockchainAPIWeb.Endpoint,
  http: [port: port],
  url: [host: System.get_env("HOSTNAME") || "localhost", port: port],
  server: true,
  root: ".",
  version: Application.spec(:blockchain_api, :vsn),
  check_origin: false,
  # force_ssl: [hsts: true, rewrite_on: [:x_forwarded_proto]],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# cache_static_manifest: "priv/static/cache_manifest.json"

config :blockchain_api,
  env: Mix.env(),
  google_maps_secret: System.get_env("GOOGLE_MAPS_API_KEY"),
  notifier_client: BlockchainAPI.FakeNotifierClient

# Configure your database
config :blockchain_api, BlockchainAPI.Repo,
  username: System.get_env("PESCADERO_DB_USER"),
  password: System.get_env("PESCADERO_DB_PASS"),
  database: System.get_env("PESCADERO_DB"),
  hostname: System.get_env("PESCADERO_DB_HOST"),
  pool_size: 20,
  timeout: 120_000,
  log: false

# Don't connect pescadero to seed nodes
config :blockchain,
  seed_nodes: [],
  seed_node_dns: '',
  base_dir: String.to_charlist("/var/data/blockchain-api/pescadero/")
