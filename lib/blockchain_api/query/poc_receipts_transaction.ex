defmodule BlockchainAPI.Query.POCReceiptsTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  @default_limit 100

  alias BlockchainAPI.{
    Util,
    Repo,
    Schema.POCReceiptsTransaction,
    Schema.POCPathElement,
    Schema.Transaction
  }

  def show!(id) do
    path_query()
    |> receipt_query(id)
    |> Repo.one!()
    |> encode_entry()
  end

  def list(_) do
    POCReceiptsTransaction
    |> Repo.all()
  end

  def challenges(%{"before" => before, "limit" => limit}=_params) do
    path_query()
    |> receipt_query()
    |> filter_before(before, limit)
    |> Repo.all()
    |> encode()
  end
  def challenges(%{"before" => before}=_params) do
    path_query()
    |> receipt_query()
    |> filter_before(before, @default_limit)
    |> Repo.all()
    |> encode()
  end
  def challenges(%{"limit" => limit}=_params) do
    path_query()
    |> receipt_query()
    |> limit(^limit)
    |> Repo.all()
    |> encode()
  end
  def challenges(%{}) do
    path_query()
    |> receipt_query()
    |> Repo.all()
    |> encode()
  end

  def get!(hash) do
    POCReceiptsTransaction
    |> where([poc_receipts_txn], poc_receipts_txn.hash == ^hash)
    |> Repo.one!
  end

  def completed(_params) do
    from(poc_receipts_txn in POCReceiptsTransaction, select: count(poc_receipts_txn.id))
    |> Repo.one!
  end

  def create(attrs \\ %{}) do
    %POCReceiptsTransaction{}
    |> POCReceiptsTransaction.changeset(attrs)
    |> Repo.insert()
  end

  defp encode([]), do: []
  defp encode(entries) do
    entries |> Enum.map(&encode_entry/1)
  end

  defp encode_entry(%{challenge: entry, height: height}) do

    path_elements = entry.poc_path_elements
                    |> encode_path_elements()
                    #NOTE: The path always seems to end up in reverse order
                    |> Enum.reverse()

    # NOTE: We only mark a path as success if the last element in the path
    # had a success result. That would imply that the whole path was a success.
    last_element_result = path_elements
                          |> Enum.map(fn(element) -> element.result end)
                          |> List.last()

    success =
      case last_element_result do
        "success" -> true
        _ -> false
      end

    %{
      id: entry.id,
      challenger: Util.bin_to_string(entry.challenger),
      challenger_owner: Util.bin_to_string(entry.challenger_owner),
      hash: Util.bin_to_string(entry.hash),
      onion: Util.bin_to_string(entry.onion),
      signature: Util.bin_to_string(entry.signature),
      pathElements: path_elements,
      success: success,
      height: height
    }
  end

  defp encode_path_elements([]), do: []
  defp encode_path_elements(path_elements) do
    Enum.map(path_elements,
      fn(element) ->
        witnesses = encode_witnesses(element.poc_witness)
        receipt = encode_receipts(element.poc_receipt)
        result = result(receipt, witnesses)
        {lat, lng} = Util.h3_to_lat_lng(element.challengee_loc)
        %{
          witnesses: witnesses,
          receipt: receipt,
          result: to_string(result),
          address: Util.bin_to_string(element.challengee),
          owner: Util.bin_to_string(element.challengee_owner),
          lat: lat,
          lng: lng,
          primary: element.primary
        }
      end)
  end

  defp encode_receipts([]), do: %{}
  defp encode_receipts([receipt]) do
    {lat, lng} = Util.h3_to_lat_lng(receipt.location)
    %{
      address: Util.bin_to_string(receipt.gateway),
      owner: Util.bin_to_string(receipt.owner),
      lat: lat,
      lng: lng,
      signal: receipt.signal,
      signature: Util.bin_to_string(receipt.signature),
      origin: receipt.origin,
      time: System.convert_time_unit(receipt.timestamp, :nanosecond, :millisecond)
    }
  end

  defp encode_witnesses([]), do: []
  defp encode_witnesses(witnesses) do
    Enum.map(
      witnesses,
      fn(witness) ->
        {lat, lng} = Util.h3_to_lat_lng(witness.location)
        %{
          address: Util.bin_to_string(witness.gateway),
          owner: Util.bin_to_string(witness.owner),
          lat: lat,
          lng: lng,
          signal: witness.signal,
          signature: Util.bin_to_string(witness.signature),
          time: System.convert_time_unit(witness.timestamp, :nanosecond, :millisecond)
        }
      end)
  end

  defp result(receipt, witnesses) do
    # NOTE: We mark a failure if and only if there is no receipt AND no witnesses
    case {receipt, witnesses} do
      {rx, []} when map_size(rx) == 0 -> :failure
      {_, _} -> :success
    end
  end

  defp path_query() do
    from(
      path in POCPathElement,
      preload: [:poc_receipt, :poc_witness],
      order_by: [desc: path.id]
    )
  end

  defp receipt_query(path_query) do
    from(
      rx in POCReceiptsTransaction,
      preload: [poc_path_elements: ^path_query],
      left_join: t in Transaction,
      on: rx.hash == t.hash,
      order_by: [desc: rx.id],
      select: %{challenge: rx, height: t.block_height}
    )
  end

  defp receipt_query(path_query, id) do
    from(
      rx in POCReceiptsTransaction,
      preload: [poc_path_elements: ^path_query],
      left_join: t in Transaction,
      on: rx.hash == t.hash,
      order_by: [desc: rx.id],
      where: rx.id == ^id,
      select: %{challenge: rx, height: t.block_height}
    )
  end

  defp filter_before(query, before, limit) do
    query
    |> where([poc_rx], poc_rx.id < ^before)
    |> limit(^limit)
  end
end
