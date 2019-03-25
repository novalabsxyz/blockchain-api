defmodule BlockchainAPI.Notifier do
  use GenServer

  @me __MODULE__
  @url "https://onesignal.com/api/v1/notifications"
  @bones 100000000

  alias BlockchainAPI.Util

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
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:notify, block}, state) do

    case :blockchain_block.transactions(block) do
      [] ->
        :ok
      txns ->
        Logger.info("Notifying for block: #{:blockchain_block.height(block)}")
        Enum.map(txns, fn txn ->
          case :blockchain_txn.type(txn) do
            :blockchain_txn_payment_v1 ->
              txn
              |> payment_data()
              |> payload()
              |> encode()
              |> post()
            _ -> :ok
          end
        end)
    end

    {:noreply, state}
  end

  #==================================================================
  # Private Functions
  #==================================================================
  defp headers() do
    [
      {"Content-Type", "application/json; charset=utf-8"},
      {"Authorization", "Basic #{Application.fetch_env!(:blockchain_api, :onesignal_rest_api_key)}"}
    ]
  end

  defp payload(%{payee: address, amount: amount}=data) do
    atoms =
      case rem(amount, @bones) == 0 do
        true -> div(amount, @bones)
        false -> amount/@bones
      end

    %{
      :app_id => "#{Application.fetch_env!(:blockchain_api, :onesignal_app_id)}",
      :filters => [%{:field => "tag", :key => "address", :relation => "=", :value => address}],
      :contents => %{:en => "You got #{atoms} ATOMs!"},
      :data => data
    }
  end

  defp encode(payload) do
    {:ok, payload} = payload |> Jason.encode()
    payload
  end

  defp post(payload) do
    HTTPoison.post(@url, payload, headers())
  end

  defp payment_data(txn) do
    %{
      payee: Util.bin_to_string(:blockchain_txn_payment_v1.payee(txn)),
      amount: :blockchain_txn_payment_v1.amount(txn),
      hash: Util.bin_to_string(:blockchain_txn_payment_v1.hash(txn)),
      type: "receivedPayment"
    }
  end
end
