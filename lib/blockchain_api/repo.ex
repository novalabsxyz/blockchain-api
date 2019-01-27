defmodule BlockchainAPI.Repo do
  use Ecto.Repo,
    otp_app: :blockchain_api,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10, max_page_size: 100
end
