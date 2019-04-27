defmodule BlockchainAPI.FakeRewarder do
  use GenServer
  require Logger
  @me __MODULE__
  alias BlockchainAPI.{Query, Schema}
  @amount 1000000
  @interval 2

  #==================================================================
  # API
  #==================================================================
  def start_link(args) do
    GenServer.start_link(@me, args, name: @me)
  end

  #==================================================================
  # GenServer callbacks
  #==================================================================
  @impl true
  def init(_args) do
    :ok = :blockchain_event.add_handler(self())
    chain = :blockchain_worker.blockchain()
    {:ok, public_key, sigfun} = :blockchain_swarm.keys()
    payer = :libp2p_crypto.pubkey_to_bin(public_key)
    {:ok, %{payer: payer, sigfun: sigfun, reward_height: 0, chain: chain}}
  end

  @impl true
  def handle_info({:blockchain_event, {:integrate_genesis_block, {:ok, _genesis_hash}}}, state) do
    chain = :blockchain_worker.blockchain()
    {:noreply, Map.put(state, :chain, chain)}
  end

  @impl true
  def handle_info({:blockchain_event, {:add_block, hash, false}}, %{:reward_height => reward_height, :chain => chain}=state) do
    {:ok, block} = :blockchain.get_block(hash, chain)
    block_height = :blockchain_block.height(block)

    case block_height >= (@interval + reward_height) do
      true ->
        case reward_hotspots(state) do
          :ok ->
            Logger.info("Rewarding ok")
          {:error, reason} ->
            Logger.info("Reason: #{Atom.to_string(reason)}")
        end
        {:noreply, Map.put(state, :reward_height, block_height)}
      false ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  def reward_hotspots(%{:payer => payer, :sigfun => sigfun}) do
    try do
      payer_entry = Query.Account.get!(payer)
      case Query.Hotspot.all() do
        [] ->
          {:error, :no_hotspots}
        hotspots ->
          hotspots
          |> Enum.each(
            fn(hotspot) ->
              nonce = Query.Account.get_speculative_nonce(payer_entry.address)
              txn =
                :blockchain_txn_payment_v1.new(payer_entry.address,
                  hotspot.owner,
                  Enum.random(1..@amount),
                  payer_entry.fee,
                  nonce+1)
                |> :blockchain_txn.sign(sigfun)

              {:ok, _pending_txn} = Schema.PendingPayment.map(txn)
                                    |> Query.PendingPayment.create()

            end)
      end
    rescue
      _error in Ecto.NoResultsError ->
        {:error, :no_payer_entry}
    end
  end
end
