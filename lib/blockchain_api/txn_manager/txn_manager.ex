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
    GenServer.cast(@me, {:submit, txn})
  end

  # Callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:submit, txn0}, state) do
    txn = txn0 |> Base.decode64! |> :blockchain_txn.deserialize()

    case :blockchain_txn.is_valid(txn) do
      true ->
        pending_txn_hash = to_string(:libp2p_crypto.bin_to_b58(:blockchain_txn.hash(txn)))
        pending_txn_map = %{hash: pending_txn_hash}
        {:ok, pending_txn} = Explorer.create_pending_transaction(pending_txn_map)
        :blockchain_worker.submit_txn(
          txn,
          fn(res) ->
            case res do
              :ok ->
                pending_txn_hash
                |> Explorer.get_pending_transaction!()
                |> Explorer.update_pending_transaction(%{status: "done"})
              {:error, _reason} ->
                Logger.error("Failed to submit #{pending_txn_hash}")
                pending_txn_hash
                |> Explorer.get_pending_transaction!()
                |> Explorer.update_pending_transaction(%{status: "error"})
            end
          end)
      false ->
        {:error, "invalid_txn"}
    end

    {:noreply, state}
  end

end
