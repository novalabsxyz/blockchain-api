defmodule BlockchainAPI.TxnManager do

  use GenServer
  alias BlockchainAPI.{
    Query,
    Util,
    Schema.PendingPayment,
    Schema.PendingGateway,
    Schema.PendingLocation,
    Schema.PendingCoinbase,
    Schema.AccountTransaction,
    Schema.PendingTransaction
  }
  require Logger
  @me __MODULE__

  #==================================================================
  # API
  #==================================================================
  def start_link(args) do
    GenServer.start_link(@me, args, name: @me)
  end

  def submit(txn) do
    GenServer.call(@me, {:submit, txn})
  end

  #==================================================================
  # Callbacks
  #==================================================================
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:submit, txn}, _from, state) do
    try do
      pending_txn = txn
                    |> deserialize()
                    |> :blockchain_txn.hash()
                    |> Query.PendingTransaction.get!()

      case pending_txn.status do
        "done" ->
          {:reply, :done, state}
        "error" ->
          {:reply, :error, state}
        "pending" ->
          {:reply, :pending, state}
      end
    rescue
      _error in Ecto.NoResultsError ->
        :ok = submit_txn(txn)
        {:reply, :submitted, state}
    end
  end

  #==================================================================
  # Helper Functions
  #==================================================================
  defp submit_txn(txn0) do
    txn = txn0 |> deserialize()
    submit_txn(:blockchain_txn.type(txn), txn)
  end

  defp submit_txn(:blockchain_txn_payment_v1, txn) do

    {:ok, pending_txn} = PendingTransaction.map(:blockchain_txn_payment_v1, txn)
                         |> Query.PendingTransaction.create()

    {:ok, _pending_payment} = PendingPayment.map(pending_txn.hash, txn)
                             |> Query.PendingPayment.create()

    {:ok, _pending_account_txn} = :blockchain_txn_payment_v1
                                 |> AccountTransaction.map_pending(txn)
                                 |> Query.AccountTransaction.create()

    :ok = :blockchain_worker.submit_txn(
      txn,
      fn(res) ->
        case res do
          :ok ->
            Logger.info("Res: ok, Txn: #{Util.bin_to_string(pending_txn.hash)}")
          {:error, reason} ->
            Logger.error("Res: error, Reason: #{Atom.to_string(reason)}, Txn: #{Util.bin_to_string(pending_txn.hash)}")
        end
      end)
  end
  defp submit_txn(:blockchain_txn_add_gateway_v1, txn) do
    {:ok, pending_txn} = PendingTransaction.map(:blockchain_txn_add_gateway_v1, txn)
                         |> Query.PendingTransaction.create()

    {:ok, _pending_gateway} = PendingGateway.map(pending_txn.hash, txn)
                              |> Query.PendingGateway.create()

    {:ok, _pending_account_txn} = :blockchain_txn_add_gateway_v1
                                 |> AccountTransaction.map_pending(txn)
                                 |> Query.AccountTransaction.create()

    :ok = :blockchain_worker.submit_txn(
      txn,
      fn(res) ->
        case res do
          :ok ->
            Logger.info("Res: ok, Txn: #{Util.bin_to_string(pending_txn.hash)}")
          {:error, reason} ->
            Logger.error("Res: error, Reason: #{Atom.to_string(reason)}, Txn: #{Util.bin_to_string(pending_txn.hash)}")
        end
      end)
  end
  defp submit_txn(:blockchain_txn_assert_location_v1, txn) do
    {:ok, pending_txn} = PendingTransaction.map(:blockchain_txn_assert_location_v1, txn)
                         |> Query.PendingTransaction.create()

    {:ok, _pending_location} = PendingLocation.map(pending_txn.hash, txn)
                               |> Query.PendingLocation.create()

    {:ok, _pending_account_txn} = :blockchain_txn_assert_location_v1
                                 |> AccountTransaction.map_pending(txn)
                                 |> Query.AccountTransaction.create()


    :ok = :blockchain_worker.submit_txn(
      txn,
      fn(res) ->
        case res do
          :ok ->
            Logger.info("Res: ok, Txn: #{Util.bin_to_string(pending_txn.hash)}")
          {:error, reason} ->
            Logger.error("Res: error, Reason: #{Atom.to_string(reason)}, Txn: #{Util.bin_to_string(pending_txn.hash)}")
        end
      end)
  end
  defp submit_txn(:blockchain_txn_coinbase_v1, txn) do

    {:ok, pending_txn} = PendingTransaction.map(:blockchain_txn_coinbase_v1, txn)
                         |> Query.PendingTransaction.create()

    {:ok, _pending_coinbase} = PendingCoinbase.map(pending_txn.hash, txn)
                               |> Query.PendingCoinbase.create()

    {:ok, _pending_account_txn} = :blockchain_txn_coinbase_v1
                                 |> AccountTransaction.map_pending(txn)
                                 |> Query.AccountTransaction.create()

    :ok = :blockchain_worker.submit_txn(
      txn,
      fn(res) ->
        case res do
          :ok ->
            Logger.info("Res: ok, Txn: #{Util.bin_to_string(pending_txn.hash)}")
          {:error, reason} ->
            Logger.error("Res: error, Reason: #{Atom.to_string(reason)}, Txn: #{Util.bin_to_string(pending_txn.hash)}")
        end
      end)
  end

  def deserialize(txn) do
    txn |> Base.decode64! |> :blockchain_txn.deserialize()
  end
end
