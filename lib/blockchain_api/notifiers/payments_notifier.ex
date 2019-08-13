defmodule BlockchainAPI.PaymentsNotifier do
  use GenServer
  require Logger

  @me __MODULE__
  @bones 100000000
  @ticker "HLM"

  alias BlockchainAPI.{NotifierClient, Util}

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
  def handle_info({:blockchain_event, {:add_block, hash, false, _}}, %{:chain => chain}=state) do
    {:ok, block} = :blockchain.get_block(hash, chain)
    case :blockchain_block.transactions(block) do
      [] ->
        :ok
      txns ->
        Logger.info("Notifying for block: #{:blockchain_block.height(block)}")
        Enum.map(txns, fn txn ->
          case :blockchain_txn.type(txn) do
            :blockchain_txn_payment_v1 ->
              amount = :blockchain_txn_payment_v1.amount(txn)
              NotifierClient.post(payment_data(txn, amount), amount |> units() |> message())
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

  #==================================================================
  # Private Functions
  #==================================================================

  defp payment_data(txn, amount) do
    %{
      address: Util.bin_to_string(:blockchain_txn_payment_v1.payee(txn)),
      amount: amount,
      hash: Util.bin_to_string(:blockchain_txn_payment_v1.hash(txn)),
      type: "receivedPayment"
    }
  end

  defp message(units) do
    "You got #{units} #{@ticker}"
  end

  def units(amount) when is_integer(amount) do
    amount |> Decimal.div(@bones) |> delimit_unit()
  end
  def units(amount) when is_float(amount) do
    amount |> Decimal.from_float() |> Decimal.div(@bones) |> delimit_unit()
  end

  defp delimit_unit(units0) do
    unit_str = units0 |> Decimal.to_string()
    case :binary.match(unit_str, ".") do
      {start, _} ->
        precision = byte_size(unit_str) - start - 1
        units0
        |> Decimal.to_float()
        |> Number.Delimit.number_to_delimited(precision: precision)
        |> String.trim_trailing("0")

      :nomatch ->
        units0
        |> Decimal.to_float()
        |> Number.Delimit.number_to_delimited(precision: 0)
    end
  end

end
