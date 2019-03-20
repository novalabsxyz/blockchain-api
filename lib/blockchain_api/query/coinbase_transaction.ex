defmodule BlockchainAPI.Query.CoinbaseTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.CoinbaseTransaction}

  def list(params) do
    CoinbaseTransaction
    |> Repo.paginate(params)
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
