defmodule BlockchainAPI.Job.SubmitSecExchange do
  alias BlockchainAPI.Query.PendingSecExchange
  alias BlockchainAPI.Util
  require Logger

  def run(id) do
    Logger.debug("running pending_sec_exchange job: #{inspect(id)}")

    pending_sec_exchange = PendingSecExchange.get_by_id!(id)
    txn = pending_sec_exchange.txn |> :blockchain_txn.deserialize()

    txn
    |> :blockchain_worker.submit_txn(fn res ->
      case res do
        :ok ->
          Logger.info("Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} accepted!")

          pending_sec_exchange
          |> PendingSecExchange.update!(%{status: "cleared"})

        {:error, reason} ->
          Logger.error(
            "Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} failed!, reason: #{
              inspect(reason)
            }"
          )

          pending_sec_exchange
          |> PendingSecExchange.update!(%{status: "error"})
      end
    end)
  end
end
