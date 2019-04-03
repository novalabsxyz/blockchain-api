defmodule BlockchainAPI.Query.POCRequestTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.POCRequestTransaction}

  def list(_params) do
    POCRequestTransaction
    |> Repo.all()
  end

  def get!(hash) do
    POCRequestTransaction
    |> where([poc_req_txn], poc_req_txn.hash == ^hash)
    |> Repo.one!
  end

  def create(attrs \\ %{}) do
    %POCRequestTransaction{}
    |> POCRequestTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
