defmodule BlockchainAPI.Query.POCReceiptsTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Schema.POCReceiptsTransaction,
    Schema.POCPathElement
  }

  def list(_) do
    POCReceiptsTransaction
    |> Repo.all()
  end

  def challenges(_params) do
    path_query = from(path in POCPathElement, preload: [:poc_receipt, :poc_witness])
    receipt_query = from(rx in POCReceiptsTransaction, preload: [poc_path_elements: ^path_query])
    receipt_query |> Repo.all()
  end

  def get!(hash) do
    POCReceiptsTransaction
    |> where([poc_receipts_txn], poc_receipts_txn.hash == ^hash)
    |> Repo.one!
  end

  def create(attrs \\ %{}) do
    %POCReceiptsTransaction{}
    |> POCReceiptsTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
