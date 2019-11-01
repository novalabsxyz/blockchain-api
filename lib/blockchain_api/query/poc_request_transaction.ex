defmodule BlockchainAPI.Query.POCRequestTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Schema.POCRequestTransaction,
    Schema.POCReceiptsTransaction,
    Util
  }

  def list(_params) do
    POCRequestTransaction
    |> Repo.all()
  end

  def get!(hash) do
    POCRequestTransaction
    |> where([poc_req_txn], poc_req_txn.hash == ^hash)
    |> Repo.one!()
  end

  # NOTE: onions are supposed to always have a unique hash
  def get_by_onion(onion) do
    POCRequestTransaction
    |> where([poc_req_txn], poc_req_txn.onion == ^onion)
    |> Repo.one!()
  end

  def create(attrs \\ %{}) do
    %POCRequestTransaction{}
    |> POCRequestTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def get_challenge(poc_request) do
    poc_request
    |> Repo.preload(:poc_receipts_transactions)
    |> Map.get(:poc_receipts_transactions)
  end

  def list_for(challenger) do
    from(
      req in POCRequestTransaction,
      left_join: receipt in POCReceiptsTransaction,
      on: req.id == receipt.poc_request_transactions_id,
      where: req.challenger == ^challenger,
      order_by: [desc: req.id],
      select: %{
        request_id: req.id,
        challenger: req.challenger,
        owner: req.owner,
        onion: req.onion,
        request_hash: req.hash,
        receipt_hash: receipt.hash,
        receipt_id: receipt.id
      }
    )
    |> Repo.all()
    |> encode()
  end

  defp encode([]), do: []
  defp encode(list) do
    list |> Enum.map(&encode_entry/1)
  end

  defp encode_entry(%{challenger: c, owner: own, request_hash: h, receipt_hash: nil, onion: o}=map) do
    %{map |
      challenger: Util.bin_to_string(c),
      owner: Util.bin_to_string(own),
      request_hash: Util.bin_to_string(h),
      onion: Util.bin_to_string(o)}
  end
  defp encode_entry(%{challenger: c, owner: own, request_hash: h, receipt_hash: rh, onion: o}=map) do
    %{map |
      challenger: Util.bin_to_string(c),
      owner: Util.bin_to_string(own),
      request_hash: Util.bin_to_string(h),
      receipt_hash: Util.bin_to_string(rh),
      onion: Util.bin_to_string(o)}
  end

end
