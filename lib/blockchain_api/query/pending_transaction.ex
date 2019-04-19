defmodule BlockchainAPI.Query.PendingTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingTransaction}

  def create(attrs \\ %{}) do
    %PendingTransaction{}
    |> PendingTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    PendingTransaction
    |> where([pt], pt.hash == ^hash)
    |> Repo.one!
  end

  def update!(pt, attrs \\ %{}) do
    pt
    |> PendingTransaction.changeset(attrs)
    |> Repo.update!()
  end

  def delete!(pt, attrs \\ %{}) do
    pt
    |> PendingTransaction.changeset(attrs)
    |> Repo.delete!()
  end
end
