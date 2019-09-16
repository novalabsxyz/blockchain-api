defmodule BlockchainAPI.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :blockchain_api,
    adapter: Ecto.Adapters.Postgres,
    loggers: [{Ecto.LogEntry, :log, [:info]}]
end
