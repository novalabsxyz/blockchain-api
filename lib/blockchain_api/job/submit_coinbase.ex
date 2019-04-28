defmodule BlockchainAPI.Job.SubmitCoinbase do
  alias BlockchainAPI.Query.PendingCoinbase
  alias BlockchainAPI.Util
  require Logger

  def run(id) do
    Logger.debug("running job for #{inspect(id)}")

    pending_coinbase = PendingCoinbase.get_by_id!(id)
    txn = pending_coinbase.txn |> :blockchain_txn.deserialize()

    txn
    |> :blockchain_worker.submit_txn(
      fn(res) ->
        case res do
          :ok ->
            Logger.info("Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} accepted!")
            pending_coinbase
            |> PendingCoinbase.update!(%{status: "cleared"})
          {:error, reason} ->
            Logger.error("Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} failed!, reason: #{inspect(reason)}")
            pending_coinbase
            |> PendingCoinbase.update!(%{status: "error"})
        end
      end)
  end
end
