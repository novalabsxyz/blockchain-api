defmodule BlockchainAPI.Job.SubmitPayment do
  alias BlockchainAPI.Query.PendingPayment
  alias BlockchainAPI.Util
  require Logger

  def run(id) do
    Logger.debug("running pending_payment job: #{inspect(id)}")

    pending_payment = PendingPayment.get_by_id!(id)
    txn = pending_payment.txn |> :blockchain_txn.deserialize()

    txn
    |> :blockchain_worker.submit_txn(
      fn(res) ->
        case res do
          :ok ->
            Logger.info("Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} accepted!")
            pending_payment
            |> PendingPayment.update!(%{status: "cleared"})
          {:error, reason} ->
            Logger.error("Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} failed!, reason: #{inspect(reason)}")
            pending_payment
            |> PendingPayment.update!(%{status: "error"})
        end
      end)
  end
end
