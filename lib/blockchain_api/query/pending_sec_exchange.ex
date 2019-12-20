defmodule BlockchainAPI.Query.PendingSecExchange do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, RORepo, Schema.PendingSecExchange}

  def create(attrs \\ %{}) do
    %PendingSecExchange{}
    |> PendingSecExchange.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    PendingSecExchange
    |> where([psec], psec.hash == ^hash)
    |> RORepo.one!()
  end

  def get_by_id!(id) do
    PendingSecExchange
    |> where([psec], psec.id == ^id)
    |> RORepo.one!()
  end

  def update!(psec, attrs \\ %{}) do
    psec
    |> PendingSecExchange.changeset(attrs)
    |> Repo.update!()
  end
end
