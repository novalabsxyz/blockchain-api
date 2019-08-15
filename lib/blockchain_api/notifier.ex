defmodule BlockchainAPI.Notifier do
  use GenServer
  require Logger

  alias BlockchainAPI.{HotspotNotifier, PaymentsNotifier}

  #==================================================================
  # API
  #==================================================================
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def send_notifications(block, ledger) do
    GenServer.cast(__MODULE__, {:notify, block, ledger})
  end

  #==================================================================
  # Callbacks
  #==================================================================

  @impl true
  def init(_args) do
    chain = :blockchain_worker.blockchain()
    {:ok, %{chain: chain}}
  end

  @impl true
  def handle_cast({:notify, block, ledger}, state) do
    case :blockchain_block.transactions(block) do
      [] ->
        :ok
      txns ->
        Enum.map(txns, fn txn ->
          case :blockchain_txn.type(txn) do
            :blockchain_txn_payment_v1 ->
              Logger.info("Notifying for payments from block: #{:blockchain_block.height(block)}")
              PaymentsNotifier.send_notification(txn)
            :blockchain_txn_add_gateway_v1
              Logger.info("Notifying new hotspots from block: #{:blockchain_block.height(block)}")
              HotspotNotifier.send_new_hotspot_notification(txn, :blockchain_txn_add_gateway_v1, ledger)
            _ -> :ok
          end
        end)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end
end
