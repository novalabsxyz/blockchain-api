use Mix.Config

port = String.to_integer(System.get_env("PORT") || "4002")

config :blockchain_api, BlockchainAPIWeb.Endpoint,
  http: [port: port],
  url: [host: System.get_env("HOSTNAME") || "localhost", port: port],
  server: true,
  root: ".",
  version: Application.spec(:blockchain_api, :vsn),
  check_origin: false,
  secret_key_base: "783ef8381ceb304d0bd6a62f2bb256751dae3969e8eadd0358fbd47797dd0bee"

# Only debug statements for tests
config :logger, level: :debug

# Preset database configuration for tests
# Configure your database
config :blockchain_api, BlockchainAPI.Repo,
  username: "postgres",
  password: "postgres",
  database: "blockchain-api-test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  timeout: 60000,
  log: false

config :blockchain_api,
  env: Mix.env(),
  notifier_client: BlockchainAPI.FakeNotifierClient,
  repos: [master: BlockchainAPI.Repo, replica: BlockchainAPI.Repo]  # no replica in test mode

# Don't connect dev to seed nodes
config :blockchain,
  seed_nodes: [],
  seed_node_dns: '',
  base_dir: String.to_charlist("/tmp/blockchain-api/test/"),
  peerbook_update_interval: 60000,
  peerbook_allow_rfc1918: true,
  peer_cache_timeout: 20000
