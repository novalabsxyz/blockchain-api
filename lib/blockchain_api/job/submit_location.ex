defmodule BlockchainAPI.Job.SubmitLocation do
  alias BlockchainAPI.Query.PendingLocation
  alias BlockchainAPI.Util
  require Logger

  def run(id) do
    Logger.debug("running pending_location job: #{inspect(id)}")

    pending_location = PendingLocation.get_by_id!(id)
    txn = pending_location.txn |> :blockchain_txn.deserialize()

    txn
    |> :blockchain_worker.submit_txn(
      fn(res) ->
        case res do
          :ok ->
            Logger.info("Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} accepted!")
            pending_location
            |> PendingLocation.update!(%{status: "cleared"})
          {:error, reason} ->
            Logger.error("Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} failed!, reason: #{inspect(reason)}")
            pending_location
            |> PendingLocation.update!(%{status: "error"})
        end
      end)
  end
end
