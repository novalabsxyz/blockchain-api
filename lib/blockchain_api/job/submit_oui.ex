defmodule BlockchainAPI.Job.SubmitOUI do
  alias BlockchainAPI.Query.PendingOUI
  alias BlockchainAPI.Util
  require Logger

  def run(id) do
    Logger.debug("running pending_oui job: #{inspect(id)}")

    pending_oui = PendingOUI.get_by_id!(id)

    IO.inspect(pending_oui, label: :pending_oui)
    IO.inspect(pending_oui.txn, label: :pending_oui_txn)

    txn = pending_oui.txn |> :blockchain_txn.deserialize()

    IO.inspect(txn, label: :before_submit)

    txn
    |> :blockchain_worker.submit_txn(fn res ->
      case res do
        :ok ->
          Logger.info("Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} accepted!")

          pending_oui
          |> PendingOUI.update!(%{status: "cleared"})

        {:error, reason} ->
          Logger.error(
            "Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} failed!, reason: #{
              inspect(reason)
            }"
          )

          pending_oui
          |> PendingOUI.update!(%{status: "error"})
      end
    end)
  end
end
