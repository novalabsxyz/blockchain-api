defmodule BlockchainAPI.Query.CoinbaseTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.CoinbaseTransaction}

  def list(_params) do
    CoinbaseTransaction
    |> order_by([ct], [desc: ct.id])
    |> Repo.all()
  end

  def get!(hash) do
    CoinbaseTransaction
    |> where([ct], ct.hash == ^hash)
    |> Repo.one!
  end

  def create(attrs \\ %{}) do
    %CoinbaseTransaction{}
    |> CoinbaseTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
