defmodule BlockchainAPI.Query.PendingGateway do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingGateway}

  def create_pending_gateway(attrs \\ %{}) do
    %PendingGateway{}
    |> PendingGateway.changeset(attrs)
    |> Repo.insert()
  end

  def get_pending_gateway!(hash) do
    PendingGateway
    |> where([pg], pg.hash == ^hash)
    |> Repo.one!
  end

  def update_pending_gateway!(pg, attrs \\ %{}) do
    pg
    |> PendingGateway.changeset(attrs)
    |> Repo.update!()
  end
end
