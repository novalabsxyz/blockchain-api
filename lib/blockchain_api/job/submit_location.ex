defmodule BlockchainAPI.Job.SubmitLocation do
  alias BlockchainAPI.Query.PendingLocation
  alias BlockchainAPI.Util
  require Logger

  @blacklisted_owner BlockchainAPI.Util.string_to_bin("14CJX5YCRf94kbhL9PPn58SL9EzqUGsrALeaEar4UikM4EB3Mx7")

  def run(id) do
    Logger.debug("running pending_location job: #{inspect(id)}")

    pending_location = PendingLocation.get_by_id!(id)
    txn = pending_location.txn |> :blockchain_txn.deserialize()

    case :blockchain_txn_assert_location_v1.owner(txn) do
      @blacklisted_owner ->
        Logger.error("You are blacklisted! Job id: #{id}")

        # Mark as error right away
        pending_location
        |> PendingLocation.update!(%{status: "error"})

      _ ->

        txn
        |> :blockchain_worker.submit_txn(fn res ->
          case res do
            :ok ->
              Logger.info("Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} accepted!")

              pending_location
              |> PendingLocation.update!(%{status: "cleared"})

            {:error, reason} ->
              Logger.error(
                "Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} failed!, reason: #{
                  inspect(reason)
                }"
              )

              pending_location
              |> PendingLocation.update!(%{status: "error"})
          end
        end)
    end
  end
end
