defmodule BlockchainAPI.Query.PaymentTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PaymentTransaction}

  def list_payment_transactions(params) do
    PaymentTransaction
    |> Repo.paginate(params)
  end

  def get_payment!(hash) do
    PaymentTransaction
    |> where([pt], pt.hash == ^hash)
    |> Repo.one!
  end

  def create_payment(txn_hash, attrs \\ %{}) do
    %PaymentTransaction{hash: txn_hash}
    |> PaymentTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
