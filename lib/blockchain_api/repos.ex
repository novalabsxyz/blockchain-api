defmodule BlockchainAPI.Repo do
  use Ecto.Repo,
    otp_app: :blockchain_api,
    adapter: Ecto.Adapters.Postgres,
    loggers: [{Ecto.LogEntry, :log, [:debug]}]

  @replica Application.get_env(:blockchain_api, :repos)[:replica]

  def replica() do
    @replica
  end
end
