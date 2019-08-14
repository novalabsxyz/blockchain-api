defmodule BlockchainAPI.Notifier do
  use GenServer
  require Logger

  @me __MODULE__

  alias BlockchainAPI.{HotspotNotifier, PaymentsNotifier}

  #==================================================================
  # API
  #==================================================================
  def start_link(args) do
    GenServer.start_link(@me, args, name: @me)
  end

  def notify(block) do
    GenServer.cast(@me, {:notify, block})
  end

  #==================================================================
  # Callbacks
  #==================================================================
  @impl true
  def init(_state) do
    :ok = :blockchain_event.add_handler(self())
    chain = :blockchain_worker.blockchain()
    {:ok, %{chain: chain}}
  end

  @impl true
  def handle_info({:blockchain_event, {:integrate_genesis_block, {:ok, _genesis_hash}}}, state) do
    chain = :blockchain_worker.blockchain()
    {:noreply, Map.put(state, :chain, chain)}
  end

  @impl true
  def handle_info({:blockchain_event, {_, _, true, _}}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:blockchain_event, {:add_block, hash, false, ledger}}, %{:chain => chain}=state) do
    {:ok, block} = :blockchain.get_block(hash, chain)
    case :blockchain_block.transactions(block) do
      [] ->
        :ok
      txns ->
        Logger.info("Notifying for block: #{:blockchain_block.height(block)}")
        Enum.map(txns, fn txn ->
          case :blockchain_txn.type(txn) do
            :blockchain_txn_payment_v1 ->
              PaymentsNotifier.send_notification(txn)
            :blockchain_txn_add_gateway_v1 = type ->
              HotspotNotifier.send_new_hotspot_notification(txn, type, ledger)
            _ -> :ok
          end
        end)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(msg, %{:chain => :undefined}) do
    chain = :blockchain_worker.blockchain()
    Process.send_after(self(), msg, :timer.minutes(1))
    {:noreply, %{chain: chain}}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end
end
