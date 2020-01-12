defmodule BlockchainAPI.Query.OUITransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.OUITransaction}

  def list(_params) do
    OUITransaction
    |> order_by([oui], desc: [oui.id])
    |> Repo.replica.all()
  end

  def get!(hash) do
    OUITransaction
    |> where([oui], oui.hash == ^hash)
    |> Repo.replica.one!()
  end

  def create(attrs \\ %{}) do
    %OUITransaction{}
    |> OUITransaction.changeset(attrs)
    |> Repo.insert()
  end
end
