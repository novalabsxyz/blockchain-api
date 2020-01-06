defmodule BlockchainAPI.Query.PaymentTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, RORepo, Schema.PaymentTransaction}

  def list(_params) do
    PaymentTransaction
    |> order_by([pt], desc: pt.id)
    |> RORepo.all()
  end

  def get!(hash) do
    PaymentTransaction
    |> where([pt], pt.hash == ^hash)
    |> RORepo.one!()
  end

  def create(attrs \\ %{}) do
    %PaymentTransaction{}
    |> PaymentTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
