defmodule BlockchainAPI.FakeNotifierClient do
  def post(data, message, opts \\ %{}) do
    {:ok, %{}}
  end

  defp headers() do
    [
      {"Content-Type", "application/json; charset=utf-8"},
      {"Authorization", "Basic onesignal_rest_api_key"}
    ]
  end

  defp to_payload(data, message, opts) do
    %{
      :app_id => "onesignal_app_id",
      :filters => [%{:field => "tag", :key => "address", :relation => "=", :value => data.address}],
      :contents => %{:en => message},
      :data => data
    }
    |> Map.merge(opts)
    |> encode()
  end

  defp encode(payload) do
    {:ok, payload} = payload |> Jason.encode()
    payload
  end
end
