defmodule BlockchainAPI.PeriodicCleaner do
  @moduledoc """
  This module will look at pending payment transactions (for now)
  and eagerly error out those transactions which haven't cleared for
  past 20 blocks.
  """

  use GenServer
  alias BlockchainAPI.{Query, Util}
  require Logger

  @me __MODULE__
  # Wait for 50 blocks for txn to clear
  @max_height 50

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
    # Schedule cleanup every minute
    Process.send_after(self(), :clean, :timer.minutes(1))
  end

  defp handle_pending_txn(mod, chain) do
    apply(mod, :list_pending, [])
    |> Enum.reject(fn entry -> pending_txn_appeared_on_chain?(mod, entry, chain) end)
    |> Enum.filter(fn entry -> filter_long_standing?(entry, chain) end)
    |> Enum.map(fn p ->
      Logger.info("Marking txn: #{Util.bin_to_string(p.hash)} as error, pending_txn_submission_height: #{p.submit_height}")
      apply(mod, :update!, [p, %{status: "error"}])
    end)
  end

  defp pending_txn_appeared_on_chain?(mod, entry, chain) do
    chain_height = :blockchain.height(chain)

    case chain_height >= entry.submit_height do
      false ->
        false

      true ->
        txns_so_far = txn_hashes_since_pending_submission(entry.submit_height, entry.hash, chain)

        case Enum.member?(txns_so_far, entry.hash) do
          false ->
            false

          true ->
            # pending txn appeared on chain
            # mark it as cleared and return true for rejection
            apply(mod, :update!, [entry, %{status: "cleared"}])
            true
        end
    end
  end

  defp filter_long_standing?(entry, chain) do
    chain_height = :blockchain.height(chain)
    (chain_height - entry.submit_height) >= @max_height
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

end
