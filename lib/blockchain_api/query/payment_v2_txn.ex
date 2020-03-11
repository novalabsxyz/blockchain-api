defmodule BlockchainAPI.Query.PaymentV2Txn do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PaymentV2Txn}

  def list(_params) do
    PaymentV2Txn
    |> order_by([pt], desc: pt.id)
    |> Repo.replica.all()
  end

  def get!(hash) do
    PaymentV2Txn
    |> where([pt], pt.hash == ^hash)
    |> Repo.replica.one!()
  end

  def create(attrs \\ %{}) do
    %PaymentV2Txn{}
    |> PaymentV2Txn.changeset(attrs)
    |> Repo.insert()
  end
end
