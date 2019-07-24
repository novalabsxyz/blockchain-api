defmodule BlockchainAPI.Query.POCRequestTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Query,
    Schema.POCRequestTransaction,
    Schema.Block
  }

  def list(_params) do
    POCRequestTransaction
    |> Repo.all()
  end

  def get!(hash) do
    POCRequestTransaction
    |> where([poc_req_txn], poc_req_txn.hash == ^hash)
    |> Repo.one!
  end

  # NOTE: onions are supposed to always have a unique hash
  def get_by_onion(onion) do
    POCRequestTransaction
    |> where([poc_req_txn], poc_req_txn.onion == ^onion)
    |> Repo.one!
  end

  def ongoing(params) do
    height = from(b in Block, select: (max(b.height) - 1)) |> Repo.one!()
    txns = Query.Transaction.at_height(height, params)
    length(Enum.filter(txns, fn(txn) -> txn.type == "poc_request" end))
  end

  def create(attrs \\ %{}) do
    %POCRequestTransaction{}
    |> POCRequestTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def challenge(poc_request) do
    poc_request
    |> Repo.preload(:poc_receipts_transactions)
    |> Map.get(:poc_receipts_transactions)
  end
end
