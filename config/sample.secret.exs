# This is a sample secret file a dev would need to add under config/
# Remember to rename it to `prod.secret.exs`

use Mix.Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).
config :blockchain_api, BlockchainAPIWeb.Endpoint, secret_key_base: "some long encoded secret"

# Configure your database
config :blockchain_api, BlockchainAPI.Repo,
  username: "username",
  password: "password",
  database: "blockchain_api_prod",
  pool_size: 15
