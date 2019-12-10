defmodule BlockchainAPI.Notifier do
  use GenServer
  require Logger

  alias BlockchainAPI.{
    HotspotNotifier,
    PaymentsNotifier,
    Query.PendingGateway,
    Schema.Hotspot
  }

  # ==================================================================
  # API
  # ==================================================================
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def notify(block, ledger) do
    GenServer.cast(__MODULE__, {:notify, block, ledger})
  end

  # ==================================================================
  # Callbacks
  # ==================================================================

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

            :blockchain_txn_add_gateway_v1 ->
              try do
                Hotspot.map(:blockchain_txn_add_gateway_v1, txn, ledger)
                |> Map.get(:address)
                |> PendingGateway.get!()
                |> HotspotNotifier.send_new_hotspot_notification()

                Logger.info("Notified new hotspots for block: #{:blockchain_block.height(block)}")

              rescue
                _error in Ecto.NoResultsError ->
                  Logger.error("Notification for new hotspots for block: #{:blockchain_block.height(block)} failed")
              end

            _ ->
              :ok
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
