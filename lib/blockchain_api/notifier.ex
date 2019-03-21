defmodule BlockchainAPI.Notifier do
  use GenServer

  @me __MODULE__
  @url "https://onesignal.com/api/v1/notifications"

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
        Enum.map(txns, fn txn ->
          case :blockchain_txn.type(txn) do
            :blockchain_txn_payment_v1 ->

              payee = :blockchain_txn_payment_v1.payee(txn)
              amount = :blockchain_txn_payment_v1.amount(txn)

              payee
              |> Util.bin_to_string()
              |> payload(amount)
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

  defp payload(address, amount) do
    %{
      :app_id => "#{Application.fetch_env!(:blockchain_api, :onesignal_app_id)}",
      :filters => [%{:field => "tag", :key => "address", :relation => "=", :value => address}],
      :contents => %{:en => "You got #{amount/100000000} ATOMs!"}
    }
  end

  defp encode(payload) do
    {:ok, payload} = payload |> Jason.encode()
    payload
  end

  defp post(payload) do
    HTTPoison.post(@url, payload, headers())
  end
end
