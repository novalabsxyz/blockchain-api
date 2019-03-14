defmodule BlockchainAPI.Query.CoinbaseTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.CoinbaseTransaction}

  def list_coinbase_transactions(params) do
    CoinbaseTransaction
    |> Repo.paginate(params)
  end

  def get_coinbase!(hash) do
    CoinbaseTransaction
    |> where([ct], ct.hash == ^hash)
    |> Repo.one!
  end

  def create_coinbase(txn_hash, attrs \\ %{}) do
    %CoinbaseTransaction{hash: txn_hash}
    |> CoinbaseTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
