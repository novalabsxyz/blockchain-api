defmodule BlockchainAPI.Job.SubmitGateway do
  alias BlockchainAPI.Query.PendingGateway
  alias BlockchainAPI.Util
  require Logger

  @blacklisted_owner BlockchainAPI.Util.string_to_bin("14CJX5YCRf94kbhL9PPn58SL9EzqUGsrALeaEar4UikM4EB3Mx7")

  def run(id) do
    Logger.debug("running pending_gateway job: #{inspect(id)}")

    pending_gateway = PendingGateway.get_by_id!(id)
    txn = pending_gateway.txn |> :blockchain_txn.deserialize()

    case :blockchain_txn_add_gateway_v1.owner(txn) do
      @blacklisted_owner ->
        Logger.warn("You are blacklisted! #{inspect(txn)}")
      _ ->

        txn
        |> :blockchain_worker.submit_txn(fn res ->
          case res do
            :ok ->
              Logger.info("Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} accepted!")

              pending_gateway
              |> PendingGateway.update!(%{status: "cleared"})

            {:error, reason} ->
              Logger.error(
                "Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} failed!, reason: #{
                  inspect(reason)
                }"
                  )

              pending_gateway
              |> PendingGateway.update!(%{status: "error"})
          end
        end)
    end
  end

end
