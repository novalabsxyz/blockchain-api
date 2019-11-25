defmodule BlockchainAPI.Query.PendingSecExchange do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingSecExchange}

  def create(attrs \\ %{}) do
    %PendingSecExchange{}
    |> PendingSecExchange.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    PendingSecExchange
    |> where([psec], psec.hash == ^hash)
    |> Repo.one!()
  end

  def get_all_by_hash(hash) do
    PendingSecExchange
    |> where([psec], psec.hash == ^hash)
    |> Repo.all()
  end

  def get_by_id!(id) do
    PendingSecExchange
    |> where([psec], psec.id == ^id)
    |> Repo.one!()
  end

  def update!(psec, attrs \\ %{}) do
    psec
    |> PendingSecExchange.changeset(attrs)
    |> Repo.update!()
  end
end
