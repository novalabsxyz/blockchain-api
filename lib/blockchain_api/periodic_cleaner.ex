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
  @max_height 20 # Wait for 20 blocks for txn to clear

  #==================================================================
  # API
  #==================================================================
  def start_link(args) do
    GenServer.start_link(@me, args, name: @me)
  end

  #==================================================================
  # Callbacks
  #==================================================================
  @impl true
  def init(_state) do
    chain = :blockchain_worker.blockchain()
    schedule_cleanup()
    {:ok, %{chain: chain}}
  end

  @impl true
  def handle_info(:clean, %{:chain => chain}=state) when chain != :undefined do
    case :blockchain.height(chain) do
      {:error, _}=e ->
        Logger.error("There is no chain!")
        e
      {:ok, chain_height} ->
        Query.PendingPayment.list_pending()
        |> Enum.filter(fn(entry) -> (chain_height - entry.submit_height) >= @max_height end)
        |> Enum.map(
          fn(pp) ->
            Logger.info("Marking txn: #{inspect(Util.bin_to_string(pp.hash))} as error,
              pending_txn_submission_height: #{inspect(pp.submit_height)},
              chain_height: #{inspect(chain_height)}")
            Query.PendingPayment.update!(pp, %{status: "error"})
          end)
        Query.PendingGateway.list_pending()
        |> Enum.filter(fn(entry) -> (chain_height - entry.submit_height) >= @max_height end)
        |> Enum.map(
          fn(pp) ->
            Logger.info("Marking txn: #{inspect(Util.bin_to_string(pp.hash))} as error,
              pending_txn_submission_height: #{inspect(pp.submit_height)},
              chain_height: #{inspect(chain_height)}")
            Query.PendingGateway.update!(pp, %{status: "error"})
          end)
        Query.PendingLocation.list_pending()
        |> Enum.filter(fn(entry) -> (chain_height - entry.submit_height) >= @max_height end)
        |> Enum.map(
          fn(pp) ->
            Logger.info("Marking txn: #{inspect(Util.bin_to_string(pp.hash))} as error,
              pending_txn_submission_height: #{inspect(pp.submit_height)},
              chain_height: #{inspect(chain_height)}")
            Query.PendingLocation.update!(pp, %{status: "error"})
          end)
    end

    # reschedule cleanup
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup() do
    # Schedule cleanup every minute
    Process.send_after(self(), :clean, :timer.minutes(1))
  end
end
