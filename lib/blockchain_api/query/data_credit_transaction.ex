defmodule BlockchainAPI.Query.DataCreditTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.DataCreditTransaction}

  def get_balance(address) do
    res =
      DataCreditTransaction
      |> where([ct], ct.payee == ^address)
      |> order_by([ct], desc: ct.id)
      |> limit(1)
      |> Repo.one()

    case res do
      nil -> 0
      dc -> dc.amount
    end
  end

  def get!(hash) do
    DataCreditTransaction
    |> where([ct], ct.hash == ^hash)
    |> Repo.one!()
  end

  def create(attrs \\ %{}) do
    %DataCreditTransaction{}
    |> DataCreditTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
