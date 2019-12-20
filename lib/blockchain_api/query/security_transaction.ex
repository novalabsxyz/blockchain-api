defmodule BlockchainAPI.Query.SecurityTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, RORepo, Schema.SecurityTransaction}

  def list(_params) do
    SecurityTransaction
    |> order_by([ct], desc: ct.id)
    |> RORepo.all()
  end

  def get_balance(address) do
    res =
      SecurityTransaction
      |> where([ct], ct.payee == ^address)
      |> order_by([ct], desc: ct.id)
      |> limit(1)
      |> RORepo.one()

    case res do
      nil -> 0
      s -> s.amount
    end
  end

  def get!(hash) do
    SecurityTransaction
    |> where([ct], ct.hash == ^hash)
    |> RORepo.one!()
  end

  def create(attrs \\ %{}) do
    %SecurityTransaction{}
    |> SecurityTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
