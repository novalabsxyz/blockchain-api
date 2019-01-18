defmodule BlockchainAPI.Watcher do
  use GenServer
  alias BlockchainAPI.Explorer

  @me __MODULE__
  require Logger


  #==================================================================
  # API
  #==================================================================
  def start_link(args) do
    GenServer.start_link(@me, args, name: @me)
  end

  def chain() do
    GenServer.call(@me, :chain, :infinity)
  end

  def height() do
    GenServer.call(@me, :height, :infinity)
  end

  def last_block_time() do
    GenServer.call(@me, :last_block_time, :infinity)
  end

  #==================================================================
  # GenServer Callbacks
  #==================================================================
  @impl true
  def init(_args) do
    :ok = :blockchain_event.add_handler(self())
    {:ok, %{chain: nil}}
  end

  @impl true
  def handle_call(:chain, _from, state = %{chain: chain}) do
    {:reply, chain, state}
  end

  @impl true
  def handle_call(:height, _from, state = %{chain: nil}) do
    {:reply, 0, state}
  end
  def handle_call(:height, _from, state = %{chain: chain}) do
    {:ok, height} = :blockchain.height(chain)
    {:reply, height, state}
  end

  @impl true
  def handle_call(:last_block_time, _from, state = %{chain: nil}) do
    {:reply, 0, state}
  end
  def handle_call(:last_block_time, _from, state = %{chain: chain}) do
    {:ok, head_block} = :blockchain.head_block(chain)
    time = :blockchain_block.meta(head_block).block_time
    {:reply, time, state}
  end

  @impl true
  def handle_info({:blockchain_event, {:integrate_genesis_block, {:ok, genesis_hash}}}, _state) do
    Logger.info("Got integrate_genesis_block event")
    chain = :blockchain_worker.blockchain()
    {:ok, block} = :blockchain.get_block(genesis_hash, chain)
    add_block(block, chain)
    {:noreply, %{chain: chain}}
  end

  @impl true
  def handle_info({:blockchain_event, {:add_block, hash, _flag}}, state = %{chain: chain}) when chain != nil do
    # NOTE: send updates to other workers as needed here
    Logger.info("Got add_block event")
    {:ok, block} = :blockchain.get_block(hash, chain)
    add_block(block, chain)
    {:noreply, state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  #==================================================================
  # Private Functions
  #==================================================================
  defp add_block(block_to_add, chain) do
    height = :blockchain_block.height(block_to_add)
    try do
      Explorer.get_block!(height)
    rescue
      e in Ecto.NoResultsError ->
        case Explorer.get_latest() do
          [nil] ->
            # nothing in the db yet
            block = Explorer.create_block(block_map(block_to_add))
            add_transactions(block_to_add)
          [last_known_height] ->
            case height > last_known_height do
              true ->
                missing_blocks =
                  Range.new(last_known_height + 1, height)
                  |> Enum.map(fn h ->
                    {:ok, b} = :blockchain.get_block(h, chain)
                    b
                  end)

                Enum.map(missing_blocks, fn b -> Explorer.create_block(block_map(b)) end)

                Enum.map(missing_blocks, fn b -> add_transactions(b) end)
              false ->
                :ok
            end
        end
    end
  end

  defp add_transactions(block) do
    height = :blockchain_block.height(block)
    case :blockchain_block.transactions(block) do
      [] ->
        :ok
      txns ->
        Enum.map(txns, fn txn ->
          case :blockchain_transactions.type(txn) do
            :blockchain_txn_assert_location_v1 ->
              Explorer.create_gateway_location(assert_gw_loc_txn_map(txn, height))
            :blockchain_txn_payment_v1 ->
              Explorer.create_payment(payment_txn_map(txn, height))
            # :blockchain_txn_create_htlc_v1 ->
            # :blockchain_txn_redeem_htlc_v1 ->
            # :blockchain_txn_poc_request_v1 ->
            :blockchain_txn_add_gateway_v1 ->
              Explorer.create_gateway(add_gw_txn_map(txn, height))
            :blockchain_txn_coinbase_v1 ->
              Explorer.create_coinbase(coinbase_txn_map(txn, height))
            # :blockchain_txn_poc_receipts_v1 ->
            # blockchain_txn_gen_consensus_group_v1 ->
            _ ->
              :ok
          end
        end)
    end
  end

  defp block_map(block) do
    height = :blockchain_block.height(block)
    hash = :blockchain_block.hash_block(block) |> Base.encode16(case: :lower)
    time = :blockchain_block.meta(block).block_time
    round = :blockchain_block.meta(block).hbbft_round
    %{hash: hash, height: height, time: time, round: round}
  end


  defp coinbase_txn_map(txn, height) do
    %{
      type: "coinbase",
      payee: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_coinbase_v1.payee(txn))),
      amount: :blockchain_txn_coinbase_v1.amount(txn),
      block_height: height
    }
  end

  defp payment_txn_map(txn, height) do
    %{
      type: "payment",
      payee: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_payment_v1.payee(txn))),
      payer: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_payment_v1.payer(txn))),
      block_height: height,
      amount: :blockchain_txn_payment_v1.amount(txn),
      nonce: :blockchain_txn_payment_v1.nonce(txn),
      fee: :blockchain_txn_payment_v1.fee(txn)
    }
  end

  defp add_gw_txn_map(txn, height) do
    %{
      type: "add_gateway",
      owner: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_add_gateway_v1.owner_address(txn))),
      gateway: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_add_gateway_v1.gateway_address(txn))),
      block_height: height
    }
  end

  defp assert_gw_loc_txn_map(txn, height) do
    %{
      type: "assert_location",
      owner: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_assert_location_v1.owner_address(txn))),
      gateway: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_assert_location_v1.gateway_address(txn))),
      block_height: height,
      nonce: :blockchain_txn_assert_location_v1.nonce(txn),
      fee: :blockchain_txn_assert_location_v1.fee(txn),
      location: to_string(:h3.to_string(:blockchain_txn_assert_location_v1.location(txn)))
    }
  end

end
