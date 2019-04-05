defmodule BlockchainAPI.Repo do
  use Ecto.Repo,
    otp_app: :blockchain_api,
    adapter: Ecto.Adapters.Postgres
end
