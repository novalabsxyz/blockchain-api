defmodule BlockchainAPI.Query.CoinbaseTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, RORepo, Schema.CoinbaseTransaction}

  def list(_params) do
    CoinbaseTransaction
    |> order_by([ct], desc: ct.id)
    |> RORepo.all()
  end

  def get!(hash) do
    CoinbaseTransaction
    |> where([ct], ct.hash == ^hash)
    |> RORepo.one!()
  end

  def create(attrs \\ %{}) do
    %CoinbaseTransaction{}
    |> CoinbaseTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
