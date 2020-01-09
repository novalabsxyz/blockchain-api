defmodule BlockchainAPI.PeriodicCleaner do
  @moduledoc """
  This module will look at pending payment transactions (for now)
  and eagerly error out those transactions which haven't cleared for
  past 20 blocks.
  """

  use GenServer
  alias BlockchainAPI.{
    Query,
    HotspotNotifier,
    Schema.PendingGateway,
    Schema.PendingLocation,
    Util
  }
  require Logger

  @me __MODULE__

  # Wait for `pending_txn_blocks_to_wait` blocks for txn to clear, default to 50
  @max_height Application.get_env(:blockchain_api, :pending_txn_blocks_to_wait, 50)

  # ==================================================================
  # API
  # ==================================================================
  def start_link(args) do
    GenServer.start_link(@me, args, name: @me)
  end

  # ==================================================================
  # Callbacks
  # ==================================================================
  @impl true
  def init(_state) do
    chain = :blockchain_worker.blockchain()
    schedule_cleanup()
    {:ok, %{chain: chain}}
  end

  @impl true
  def handle_info(:clean, %{:chain => :undefined} = state) do
    {:noreply, state}
  end
  def handle_info(:clean, %{:chain => chain} = state) do
    handle_pending_txn(Query.PendingPayment, chain)
    handle_pending_txn(Query.PendingGateway, chain)
    handle_pending_txn(Query.PendingLocation, chain)

    # reschedule cleanup
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup() do
    # Schedule cleanup every `pending_txn_cleanup_interval` default to 30 minutes
    Process.send_after(self(), :clean, Application.get_env(:blockchain_api, :pending_txn_cleanup_interval, :timer.minutes(30)))
  end

  defp handle_pending_txn(mod, chain) do
    apply(mod, :list_pending, [])
    |> Enum.reject(fn entry -> pending_txn_appeared_on_chain?(mod, entry, chain) end)
    |> Enum.filter(fn entry -> filter_long_standing?(entry, chain) end)
    |> Enum.map(fn p ->
      Logger.error("Marking txn: #{Util.bin_to_string(p.hash)} as error, pending_txn_submission_height: #{p.submit_height}")
      send_failure_notifications(p)
      apply(mod, :update!, [p, %{status: "error"}])
    end)
  end

  defp pending_txn_appeared_on_chain?(mod, entry, chain) do
    case :blockchain.height(chain) do
      {:error, _} ->
        Logger.error("Could not get chain_height for pending check")
        false

      {:ok, chain_height} ->
        case chain_height >= entry.submit_height do
          false ->
            false

          true ->
            txns_so_far = txn_hashes_since_pending_submission(entry.submit_height, chain_height, chain)

            case Enum.member?(txns_so_far, entry.hash) do
              false ->
                false

              true ->
            # pending txn appeared on chain
            # mark it as cleared and return true for rejection
                Logger.info("Marking txn: #{Util.bin_to_string(entry.hash)} as cleared!")
                apply(mod, :update!, [entry, %{status: "cleared"}])
                true
            end
        end
    end
  end

  defp filter_long_standing?(entry, chain) do
    case :blockchain.height(chain) do
      {:error, _} ->
        Logger.error("Could not get chain_height for long_standing check")
        false

      {:ok, chain_height} ->
        (chain_height - entry.submit_height) >= @max_height
    end
  end

  defp txn_hashes_since_pending_submission(p_height, chain_height, chain) do
    p_height..chain_height
    |> Enum.reduce(
      [],
      fn(height, acc) ->
        case :blockchain.get_block(height, chain) do
          {:error, _} ->
            acc

          {:ok, block} ->
            case :blockchain_block.transactions(block) do
              [] ->
                acc

              txns ->
                hashes = txns |> Enum.map(fn(txn) -> :blockchain_txn.hash(txn) end)
                [hashes | acc]
            end
        end
      end)
      |> List.flatten()
  end

  defp send_failure_notifications(%PendingGateway{} = pg) do
    case Query.Hotspot.get(pg.gateway) do
      nil -> HotspotNotifier.send_add_hotspot_failed(:timed_out, pg)
        _ -> HotspotNotifier.send_add_hotspot_failed(:already_exists, pg)
    end
  end

  defp send_failure_notifications(%PendingLocation{} = pl) do
    HotspotNotifier.send_confirm_location_failed(pl)
  end

  defp send_failure_notifications(_), do: :ok
end
