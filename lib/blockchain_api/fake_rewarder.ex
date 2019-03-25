defmodule BlockchainAPI.FakeRewarder do
  use GenServer
  require Logger
  @me __MODULE__
  alias BlockchainAPI.{Query, TxnManager}
  @amount 1000000000

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
    {:ok, _, sig_fun} = :blockchain_swarm.keys()
    new_state =
      case block_height > height + 30 do
        false ->
          Logger.warn("Waiting for the next 30th block, no reward")
          state
        true ->

          case Query.Hotspot.all() do
            [] ->
              Logger.warn("No hotpots to reward!")
            hotspots ->
              Logger.info("rewarding hotspots at block_height: #{block_height}, state_height: #{height}!")
              hotspots
              |> Enum.map(fn(hotspot) ->
                payer = Query.Account.get!(:blockchain_swarm.pubkey_bin())
                nonce = Query.Account.get_speculative_nonce(payer.address)
                submission = :blockchain_txn_payment_v1.new(payer.address, hotspot.owner, Enum.random(1..@amount), payer.fee, nonce+1)
                             |> :blockchain_txn.sign(sig_fun)
                             |> :blockchain_txn.serialize()
                             |> Base.encode64()
                             |> TxnManager.submit()

                case submission do
                  :submitted -> :ok
                  _ ->
                    # TODO: Retry?
                    :ok
                end

              end)
          end

          # update height
          %{height: block_height}
      end

    {:noreply, new_state}
  end

end
