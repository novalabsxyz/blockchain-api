defmodule BlockchainAPI.Batcher.Pocs do
  @moduledoc false

  alias BlockchainAPI.{
    Query,
    Schema.POCWitness,
    Schema.POCPathElement,
    Schema.POCReceipt,
    Util
  }

  # POC Related private db helper functions. Maybe move to a separate module?
  def insert_receipt_and_witnesses(txn, block, ledger, height, poc_receipt_txn_entry) do
    deltas = :blockchain_txn_poc_receipts_v1.deltas(txn)
    time = :blockchain_block.time(block)

    txn
    |> :blockchain_txn_poc_receipts_v1.path()
    |> Enum.with_index()
    |> Enum.map(fn {element, index} when element != :undefined ->
      challengee = element |> :blockchain_poc_path_element_v1.challengee()
      res = challengee |> :blockchain_ledger_v1.find_gateway_info(ledger)

      case res do
        {:error, _} ->
          :ok

        {:ok, challengee_info} ->
          challengee_loc = :blockchain_ledger_gateway_v2.location(challengee_info)
          challengee_owner = :blockchain_ledger_gateway_v2.owner_address(challengee_info)

          delta = Enum.at(deltas, index)

          {:ok, path_element_entry} =
            POCPathElement.map(
              poc_receipt_txn_entry.hash,
              challengee,
              challengee_loc,
              challengee_owner,
              poc_result(delta)
            )
            |> Query.POCPathElement.create()

          _ =
            add_receipt(
              txn,
              height,
              time,
              ledger,
              element,
              path_element_entry,
              poc_receipt_txn_entry
            )

          _ =
            add_witnesses(
              txn,
              height,
              time,
              ledger,
              element,
              path_element_entry,
              poc_receipt_txn_entry
            )
      end
    end)
  end

  defp add_witnesses(
         txn,
         height,
         time,
         ledger,
         element,
         path_element_entry,
         poc_receipt_txn_entry
       ) do
    element
    |> :blockchain_poc_path_element_v1.witnesses()
    |> Enum.sort_by(
      fn(witness) ->
        :blockchain_poc_witness_v1.gateway(witness)
      end)
    |> Enum.map(fn witness when witness != :undefined ->
      witness_gateway = witness |> :blockchain_poc_witness_v1.gateway()

      case :blockchain_ledger_v1.find_gateway_info(witness_gateway, ledger) do
        {:error, _} ->
          :ok

        {:ok, wx_info} ->
          wx_loc = :blockchain_ledger_gateway_v2.location(wx_info)
          wx_owner = :blockchain_ledger_gateway_v2.owner_address(wx_info)
          {:ok, wx_score} = :blockchain_ledger_v1.gateway_score(witness_gateway, ledger)

          distance =
            Util.h3_distance_in_meters(
              wx_loc,
              path_element_entry.challengee_loc |> String.to_charlist() |> :h3.from_string()
            )

          {:ok, poc_witness} =
            POCWitness.map(path_element_entry.id, wx_loc, distance, wx_owner, witness)
            |> Query.POCWitness.create()

          wx_score_delta =
            case Query.HotspotActivity.last_poc_score(witness_gateway) do
              nil ->
                0.0

              s ->
                wx_score - s
            end

          {:ok, _activity_entry} =
            Query.HotspotActivity.create(%{
              gateway: witness_gateway,
              poc_rx_txn_hash: :blockchain_txn.hash(txn),
              poc_rx_txn_block_height: height,
              poc_rx_txn_block_time: time,
              poc_witness_id: poc_witness.id,
              poc_witness_challenge_id: poc_receipt_txn_entry.id,
              poc_score: wx_score,
              poc_score_delta: wx_score_delta
            })
      end
    end)
  end

  defp add_receipt(txn, height, time, ledger, element, path_element_entry, poc_receipt_txn_entry) do
    case :blockchain_poc_path_element_v1.receipt(element) do
      :undefined ->
        :ok

      receipt ->
        rx_gateway = receipt |> :blockchain_poc_receipt_v1.gateway()
        {:ok, rx_info} = rx_gateway |> :blockchain_ledger_v1.find_gateway_info(ledger)
        rx_loc = :blockchain_ledger_gateway_v2.location(rx_info)
        rx_owner = :blockchain_ledger_gateway_v2.owner_address(rx_info)
        {:ok, rx_score} = :blockchain_ledger_v1.gateway_score(rx_gateway, ledger)

        {:ok, poc_receipt} =
          POCReceipt.map(path_element_entry.id, rx_loc, rx_owner, receipt)
          |> Query.POCReceipt.create()

        rx_score_delta =
          case Query.HotspotActivity.last_poc_score(rx_gateway) do
            nil ->
              0.0

            s ->
              rx_score - s
          end

        {:ok, _activity_entry} =
          Query.HotspotActivity.create(%{
            gateway: rx_gateway,
            poc_rx_txn_hash: :blockchain_txn.hash(txn),
            poc_rx_txn_block_height: height,
            poc_rx_txn_block_time: time,
            poc_rx_id: poc_receipt.id,
            poc_rx_challenge_id: poc_receipt_txn_entry.id,
            poc_score: rx_score,
            poc_score_delta: rx_score_delta
          })

        rapid_decline(rx_gateway, time)
    end
  end

  defp rapid_decline(challengee, time) do
    challenge_results = Query.POCPathElement.get_last_ten(challengee)

    case challenge_results do
      [] ->
        :ok
      results ->
        case Enum.count(results, fn res -> res == "failure" end) do
          c when c >= 4 ->
            Query.HotspotActivity.create(%{
              gateway: challengee,
              rapid_decline: true,
              poc_rx_txn_block_time: time
            })
          _ ->
            :ok
        end
    end
  end

  defp poc_result(nil), do: "untested"
  defp poc_result({_, {0, 0}}), do: "untested"

  defp poc_result({_, {a, b}}) do
    case a > b do
      true -> "success"
      false -> "failure"
    end
  end
end
