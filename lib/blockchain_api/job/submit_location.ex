defmodule BlockchainAPI.Job.SubmitLocation do
  alias BlockchainAPI.Query.PendingLocation
  require Logger

  # By default, Honeydew will call the `run/1` function with the id of your newly inserted row.
  def run(id) do
    Logger.debug("running job for #{inspect(id)}")

    pending_location = PendingLocation.get_by_id!(id)
    txn = pending_location.txn |> :blockchain_txn.deserialize()

    txn
    |> :blockchain_worker.submit_txn(
      fn(res) ->
        case res do
          :ok ->
            Logger.info("Txn: #{inspect(:blockchain_txn.hash(txn))} accepted!")
            pending_location
            |> PendingLocation.update!(%{status: "cleared"})
          {:error, reason} ->
            Logger.error("Txn: #{inspect(:blockchain_txn.hash(txn))} failed!, reason: #{inspect(reason)}")
            pending_location
            |> PendingLocation.update!(%{status: "error"})
        end
      end)
  end
end
