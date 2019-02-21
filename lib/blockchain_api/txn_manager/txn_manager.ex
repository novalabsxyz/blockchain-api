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
      pending_txn = get_pending_transaction(txn)

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
    submit_txn(txn_type(deserialize(txn)), deserialize(txn))
  end

  defp submit_txn(:blockchain_txn_payment_v1, txn) do
    {:ok, pending_txn} = Explorer.create_pending_payment(pending_payment_map(txn))
    :ok = :blockchain_worker.submit_txn(
      txn,
      fn(res) ->
        case res do
          :ok ->
            pending_txn.hash
            |> Explorer.get_pending_payment!()
            |> Explorer.update_pending_payment(%{status: "done"})
          {:error, _reason} ->
            Logger.error("Failed to submit payment: #{pending_txn.hash}")
            pending_txn.hash
            |> Explorer.get_pending_payment!()
            |> Explorer.update_pending_payment(%{status: "error"})
        end
      end)
  end
  defp submit_txn(:blockchain_txn_add_gateway_v1, txn) do
    {:ok, pending_txn} = Explorer.create_pending_gateway(pending_gateway_map(txn))
    :ok = :blockchain_worker.submit_txn(
      txn,
      fn(res) ->
        case res do
          :ok ->
            pending_txn.hash
            |> Explorer.get_pending_gateway!()
            |> Explorer.update_pending_gateway(%{status: "done"})
          {:error, _reason} ->
            Logger.error("Failed to submit gateway: #{pending_txn.hash}")
            pending_txn.hash
            |> Explorer.get_pending_gateway!()
            |> Explorer.update_pending_gateway(%{status: "error"})
        end
      end)
  end
  defp submit_txn(:blockchain_txn_assert_location_v1, txn) do
    {:ok, pending_txn} = Explorer.create_pending_location(pending_location_map(txn))
    :ok = :blockchain_worker.submit_txn(
      txn,
      fn(res) ->
        case res do
          :ok ->
            pending_txn.hash
            |> Explorer.get_pending_location!()
            |> Explorer.update_pending_location(%{status: "done"})
          {:error, _reason} ->
            Logger.error("Failed to submit location: #{pending_txn.hash}")
            pending_txn.hash
            |> Explorer.get_pending_location!()
            |> Explorer.update_pending_location(%{status: "error"})
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

  defp pending_payment_map(txn) do
    payer = to_string(:libp2p_crypto.bin_to_b58(:blockchain_txn_payment_v1.payer(txn)))
    payee = to_string(:libp2p_crypto.bin_to_b58(:blockchain_txn_payment_v1.payee(txn)))
    nonce = :blockchain_txn_payment_v1.nonce(txn)
    fee = :blockchain_txn_payment_v1.fee(txn)
    amount = :blockchain_txn_payment_v1.amount(txn)
    %{hash: txn_hash(txn), nonce: nonce, amount: amount, fee: fee, payer: payer, payee: payee}
  end

  defp pending_gateway_map(txn) do
    owner = to_string(:libp2p_crypto.bin_to_b58(:blockchain_txn_add_gateway_v1.owner(txn)))
    gateway = to_string(:libp2p_crypto.bin_to_b58(:blockchain_txn_add_gateway_v1.gateway(txn)))
    fee = :blockchain_txn_add_gateway_v1.fee(txn)
    %{hash: txn_hash(txn), owner: owner, fee: fee, gateway: gateway}
  end

  defp pending_location_map(txn) do
    owner = to_string(:libp2p_crypto.bin_to_b58(:blockchain_txn_assert_location_v1.owner(txn)))
    gateway = to_string(:libp2p_crypto.bin_to_b58(:blockchain_txn_assert_location_v1.gateway(txn)))
    location = to_string(:h3.to_string(:blockchain_txn_assert_location_v1.location(txn)))
    nonce = :blockchain_txn_assert_location_v1.nonce(txn)
    fee = :blockchain_txn_assert_location_v1.fee(txn)
    %{hash: txn_hash(txn), nonce: nonce, fee: fee, owner: owner, location: location, gateway: gateway}
  end

  defp get_pending_transaction(txn) do
    deserialized_txn = deserialize(txn)
    get_pending_transaction(txn_type(deserialized_txn), txn_hash(deserialized_txn))
  end

  defp get_pending_transaction(:blockchain_txn_payment_v1, hash) do
    Explorer.get_pending_payment!(hash)
  end
  defp get_pending_transaction(:blockchain_txn_add_gateway_v1, hash) do
    Explorer.get_pending_gateway!(hash)
  end
  defp get_pending_transaction(:blockchain_txn_assert_location_v1, hash) do
    Explorer.get_pending_location!(hash)
  end

end
