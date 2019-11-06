defmodule BlockchainAPI.Query.SecurityExchangeTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.SecurityExchangeTransaction}

  def list(_params) do
    SecurityExchangeTransaction
    |> order_by([se], desc: se.id)
    |> Repo.all()
  end

  def get!(hash) do
    SecurityExchangeTransaction
    |> where([se], se.hash == ^hash)
    |> Repo.one!()
  end

  def create(attrs \\ %{}) do
    %SecurityExchangeTransaction{}
    |> SecurityExchangeTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
