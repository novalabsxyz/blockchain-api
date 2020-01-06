defmodule BlockchainAPI.Query.OUITransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, RORepo, Schema.OUITransaction}

  def list(_params) do
    OUITransaction
    |> order_by([oui], desc: [oui.id])
    |> RORepo.all()
  end

  def get!(hash) do
    OUITransaction
    |> where([oui], oui.hash == ^hash)
    |> RORepo.one!()
  end

  def create(attrs \\ %{}) do
    %OUITransaction{}
    |> OUITransaction.changeset(attrs)
    |> Repo.insert()
  end
end
