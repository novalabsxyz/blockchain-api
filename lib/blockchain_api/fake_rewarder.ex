defmodule BlockchainAPI.FakeRewarder do
  use GenServer
  require Logger
  @me __MODULE__
  alias BlockchainAPI.Query

  #==================================================================
  # API
  #==================================================================
  def start_link(args) do
    GenServer.start_link(@me, args, name: @me)
  end

  def reward(block) do
    GenServer.cast(@me, {:reward, block})
  end

  #==================================================================
  # GenServer callbacks
  #==================================================================
  @impl true
  def init(_args) do
    {:ok, %{height: 0}}
  end

  @impl true
  def handle_cast({:reward, block}, %{:height => height}=state) do
    block_height = :blockchain_block.height(block)
    new_state =
      case block_height >= height + 30 do
        false ->
          state
        true ->

          case Query.Hotspot.all() do
            [] ->
              Logger.warn("No hotpots to reward!")
            hotspots ->
              Logger.info("rewarding hotspots at block_height: #{block_height}, state_height: #{height}!")
              hotspots
              |> Enum.map(fn(hotspot) ->
                IO.inspect hotspot
              end)
          end

          # update height
          %{height: block_height}
      end

    {:noreply, new_state}
  end

end
