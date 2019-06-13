defmodule BlockchainAPI.Query.SecurityTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.SecurityTransaction}

  def list(_params) do
    SecurityTransaction
    |> order_by([ct], [desc: ct.id])
    |> Repo.all()
  end

  def get_balance(address) do
    SecurityTransaction
    |> where([ct], ct.payee == ^address)
    |> order_by([ct], [desc: ct.id])
    |> limit(1)
    |> Repo.one()
  end

  def get!(hash) do
    SecurityTransaction
    |> where([ct], ct.hash == ^hash)
    |> Repo.one!
  end

  def create(attrs \\ %{}) do
    %SecurityTransaction{}
    |> SecurityTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
