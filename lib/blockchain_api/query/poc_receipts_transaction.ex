defmodule BlockchainAPI.Query.POCReceiptsTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Util,
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
    receipt_query
    |> Repo.all()
    |> IO.inspect()
    |> format_challenges()
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

  defp format_challenges([]), do: []
  defp format_challenges(entries) do
    entries |> Enum.map(&encode_entry/1)
  end

  defp encode_entry(entry) do

    path_elements = encode_path_elements(entry.poc_path_elements)
    success = Enum.all?(path_elements, fn(element) -> element.result == "success" end)

    %{
      challenger: Util.bin_to_string(entry.challenger),
      hash: Util.bin_to_string(entry.hash),
      onion: Util.bin_to_string(entry.onion),
      signature: Util.bin_to_string(entry.signature),
      pathElements: path_elements,
      success: success
    }
  end

  defp encode_path_elements([]), do: []
  defp encode_path_elements(path_elements) do
    Enum.map(path_elements,
      fn(element) ->
        witnesses = encode_witnesses(element.poc_witness)
        receipts = encode_receipts(element.poc_receipt)
        result = result(receipts, witnesses)
        {lat, lng} = Util.h3_to_lat_lng(element.challengee_loc)
        %{
          witnesses: witnesses,
          receipts: receipts,
          result: to_string(result),
          address: Util.bin_to_string(element.challengee),
          lat: lat,
          lng: lng
        }
      end)
  end

  defp encode_receipts([]), do: []
  defp encode_receipts(receipts) do
    Enum.map(
      receipts,
      fn(receipt) ->
        {lat, lng} = Util.h3_to_lat_lng(receipt.location)
        %{
          address: Util.bin_to_string(receipt.gateway),
          lat: lat,
          lng: lng,
          signal: receipt.signal,
          signature: Util.bin_to_string(receipt.signature),
          origin: receipt.origin
        }
      end)
  end

  defp encode_witnesses([]), do: []
  defp encode_witnesses(witnesses) do
    Enum.map(
      witnesses,
      fn(witness) ->
        {lat, lng} = Util.h3_to_lat_lng(witness.location)
        %{
          address: Util.bin_to_string(witness.gateway),
          lat: lat,
          lng: lng,
          signal: witness.signal,
          signature: Util.bin_to_string(witness.signature)
        }
      end)
  end

  defp result(receipts, witnesses) do
    case {receipts, witnesses} do
      {[], _} -> :failure
      {_, []} -> :untested
      {_, _} -> :success
    end
  end
end
