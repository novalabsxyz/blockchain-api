defmodule BlockchainAPI.Query.PendingGateway do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingGateway}

  def create(attrs \\ %{}) do
    %PendingGateway{}
    |> PendingGateway.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    PendingGateway
    |> where([pg], pg.pending_transactions_hash == ^hash)
    |> Repo.one!
  end

  def update!(pg, attrs \\ %{}) do
    pg
    |> PendingGateway.changeset(attrs)
    |> Repo.update!()
  end
end
