defmodule BlockchainAPI.Job.SubmitBundle do
  alias BlockchainAPI.Query.{
    PendingBundle,
    PendingPayment,
    PendingGateway,
    PendingLocation,
    PendingOUI,
    PendingSecExchange}
  alias BlockchainAPI.Util
  require Logger

  def run(id) do
    Logger.debug("running pending_bundle job: #{inspect(id)}")

    pending_bundle = PendingBundle.get_by_id!(id)

    IO.inspect(pending_bundle, label: :pending_bundle)
    IO.inspect(pending_bundle.txn, label: :pending_bundle_txn)

    txn = pending_bundle.txn |> :blockchain_txn.deserialize()

    IO.inspect(txn, label: :before_submit)

    txn
    |> :blockchain_worker.submit_txn(fn res ->
      case res do
        :ok ->
          Logger.info("Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} accepted!")

          # Do this update
          update_attrs = %{status: "cleared"}

          # Mark the bundle itself
          pending_bundle |> PendingBundle.update!(update_attrs)

          # Mark all the bundled txns
          :ok = update_bundled_txns(pending_bundle, update_attrs)

        {:error, reason} ->
          Logger.error(
            "Txn: #{Util.bin_to_string(:blockchain_txn.hash(txn))} failed!, reason: #{
              inspect(reason)
            }"
          )

          # Do this update
          update_attrs = %{status: "error"}

          # Mark the bundle itself
          pending_bundle |> PendingBundle.update!(update_attrs)

          # Mark all the bundled txns
          :ok = update_bundled_txns(pending_bundle, update_attrs)
      end
    end)
  end

  defp update_bundled_txns(pending_bundle, update_attrs) do
    hashes = pending_bundle.txn_hashes
    IO.inspect(hashes, label: :hashes)
    types = pending_bundle.txn_types
    IO.inspect(types, label: :types)

    Enum.zip(types, hashes)
    |> IO.inspect()
    |> Enum.map(fn {type, hash} ->
      case type do
        "blockchain_txn_payment_v1" ->
          PendingPayment.get_all_by_hash(hash)
          |> Enum.map(fn(pp) -> PendingPayment.update!(pp, update_attrs) end)

        "blockchain_txn_add_gateway_v1" ->
          PendingGateway.get_all_by_hash(hash)
          |> Enum.map(fn(pg) -> PendingGateway.update!(pg, update_attrs) end)

        "blockchain_txn_assert_location_v1" ->
          PendingLocation.get_all_by_hash(hash)
          |> Enum.map(fn(pl) -> PendingLocation.update!(pl, update_attrs) end)

        "blockchain_txn_oui_v1" ->
          PendingOUI.get_all_by_hash(hash)
          |> Enum.map(fn(poui) -> PendingOUI.update!(poui, update_attrs) end)

        "blockchain_txn_security_exchange_v1" ->
          PendingSecExchange.get_all_by_hash(hash)
          |> Enum.map(fn(psec) -> PendingSecExchange.update!(psec, update_attrs) end)

        _ ->
          :ok

      end
    end)
  end

end
