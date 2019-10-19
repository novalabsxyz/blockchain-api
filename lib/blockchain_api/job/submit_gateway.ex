defmodule BlockchainAPI.Job.SubmitGateway do
  alias BlockchainAPI.{
    Query.Hotspot,
    Query.PendingGateway,
    HotspotNotifier,
    Util
  }
  require Logger

  @blacklisted_owner BlockchainAPI.Util.string_to_bin("14CJX5YCRf94kbhL9PPn58SL9EzqUGsrALeaEar4UikM4EB3Mx7")

  def run(id) do
    Logger.debug("running pending_gateway job: #{inspect(id)}")

    pending_gateway = PendingGateway.get_by_id!(id)
    txn = pending_gateway.txn |> :blockchain_txn.deserialize()

    case :blockchain_txn_add_gateway_v1.owner(txn) do
      @blacklisted_owner ->
        Logger.error("You are blacklisted! Job id: #{id}")

        # Mark as error right away
        pending_gateway
        |> PendingGateway.update!(%{status: "error"})

      _ ->

        txn
        |> :blockchain_worker.submit_txn(fn res ->
          case res do
            :ok ->
              Logger.info("Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} accepted!")
              notify_gateway_success(pending_gateway)

              pending_gateway
              |> PendingGateway.update!(%{status: "cleared"})

            {:error, reason} ->
              Logger.error(
                "Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} failed!, reason: #{
                  inspect(reason)
                }"
                  )
              notify_gateway_failure(pending_gateway)

              pending_gateway
              |> PendingGateway.update!(%{status: "error"})
          end
        end)
    end
  end

  defp notify_gateway_success(pending_gateway) do
    HotspotNotifier.send_new_hotspot_notification(pending_gateway)
  end

  defp notify_gateway_failure(pending_gateway) do
    case Hotspot.get(pending_gateway.gateway) do
      nil ->
        HotspotNotifier.send_add_hotspot_failed(:timed_out, pending_gateway)

      _ ->
        HotspotNotifier.send_add_hotspot_failed(:already_exists, pending_gateway)
    end
  end
end
