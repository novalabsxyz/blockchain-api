defmodule BlockchainAPI.Job.SubmitOui do
  alias BlockchainAPI.Query.PendingOui
  alias BlockchainAPI.Util
  require Logger

  def run(id) do
    Logger.debug("running pending_oui job: #{inspect(id)}")

    pending_oui = PendingOui.get_by_id!(id)
    txn = pending_oui.txn |> :blockchain_txn.deserialize()

    txn
    |> :blockchain_worker.submit_txn(fn res ->
      case res do
        :ok ->
          Logger.info("Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} accepted!")

          pending_oui
          |> PendingOui.update!(%{status: "cleared"})

        {:error, reason} ->
          Logger.error(
            "Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} failed!, reason: #{
              inspect(reason)
            }"
          )

          pending_oui
          |> PendingOui.update!(%{status: "error"})
      end
    end)
  end
end
