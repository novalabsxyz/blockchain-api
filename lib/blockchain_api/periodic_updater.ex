defmodule BlockchainAPI.PeriodicUpdater do
  @moduledoc """
  This module would update the hotspot table if the geocode lookup fails.
  It will cross-check location for a gateway address in ledger, if ledger has a loc
  and hotspot table does not, this will update it.

  Executes every minute
  """

  use GenServer
  alias BlockchainAPI.{Query, Util, Repo}
  require Logger

  @me __MODULE__

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
    schedule_update()
    {:ok, %{chain: chain}}
  end

  @impl true
  def handle_info(:update, %{:chain => chain}=state) when chain != :undefined do
    case :blockchain.height(chain) do
      {:error, _}=e ->
        Logger.error("There is no chain!")
        e
      {:ok, _chain_height} ->
        ledger = :blockchain.ledger(chain)
        hotspots_with_no_location_in_db = Query.Hotspot.all_no_loc()

        hotspots_with_location_in_ledger = hotspots_with_no_location_in_db
                                           |> Enum.reduce([],
                                             fn(hotspot, acc) ->
                                               {:ok, gateway} = :blockchain_ledger_v1.find_gateway_info(hotspot.address, ledger)
                                               case :blockchain_ledger_gateway_v1.location(gateway) do
                                                 :undefined -> acc
                                                 loc -> [{hotspot, loc} | acc]
                                               end
                                             end)

        hotspots_with_location_in_ledger
        |> Enum.each(
          fn({h, l}) ->
            loc_map = Util.reverse_geocode(l)
            Repo.update(h, loc_map)
          end)

    end

    # reschedule update
    schedule_update()
    {:noreply, state}
  end

  defp schedule_update() do
    # Schedule update every minute
    Process.send_after(self(), :update, :timer.minutes(1))
  end
end