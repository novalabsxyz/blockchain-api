defmodule BlockchainAPI.TxnManager do

  use GenServer
  alias BlockchainAPI.Explorer
  require Logger
  @me __MODULE__

  # Client
  def start_link(args) do
    GenServer.start_link(@me, args, name: @me)
  end

  def submit(txn) do
    GenServer.call(@me, {:submit, txn})
  end

  # Callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:submit, txn}, _from, state) do
    try do
      pending_txn = txn
                    |> deserialize()
                    |> txn_hash()
                    |> Explorer.get_pending_transaction!()

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

  defp submit_txn(txn) do

    deserialized_txn = txn |> deserialize()
    pending_txn_hash = deserialized_txn |> txn_hash()

    {:ok, pending_txn} = deserialized_txn
                         |> txn_map()
                         |> Explorer.create_pending_transaction()

    :ok = :blockchain_worker.submit_txn(
      deserialized_txn,
      fn(res) ->
        case res do
          :ok ->
            pending_txn.hash
            |> Explorer.get_pending_transaction!()
            |> Explorer.update_pending_transaction(%{status: "done"})
          {:error, _reason} ->
            Logger.error("Failed to submit #{pending_txn_hash}")
            pending_txn.hash
            |> Explorer.get_pending_transaction!()
            |> Explorer.update_pending_transaction(%{status: "error"})
        end
      end)
  end

  def deserialize(txn) do
    txn |> Base.decode64! |> :blockchain_txn.deserialize()
  end

  defp txn_hash(txn) do
    to_string(:libp2p_crypto.bin_to_b58(:blockchain_txn.hash(txn)))
  end

  defp txn_type(txn) do
    :blockchain_txn.type(txn)
  end

  defp txn_map(txn) do

    hash = txn_hash(txn)

    case txn_type(txn) do
      ## NOTE: only doing payment, gateway and location txns for now...
      :blockchain_txn_payment_v1 ->
        account_address = to_string(:libp2p_crypto.bin_to_b58(:blockchain_txn_payment_v1.payer(txn)))
        nonce = :blockchain_txn_payment_v1.nonce(txn)
        type = "payment"
        %{hash: hash, nonce: nonce, type: type, account_address: account_address}
      :blockchain_txn_add_gateway_v1 ->
        account_address = to_string(:libp2p_crypto.bin_to_b58(:blockchain_txn_add_gateway_v1.owner(txn)))
        ## FIXME: no nonce in add gateway txn
        nonce = -1
        type = "gateway"
        %{hash: hash, nonce: nonce, type: type, account_address: account_address}
      :blockchain_txn_assert_location_v1 ->
        account_address = to_string(:libp2p_crypto.bin_to_b58(:blockchain_txn_assert_location_v1.owner(txn)))
        nonce = :blockchain_txn_assert_location_v1.nonce(txn)
        type = "location"
        %{hash: hash, nonce: nonce, type: type, account_address: account_address}
    end

  end
end
