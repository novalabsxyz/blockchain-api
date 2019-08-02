defmodule BlockchainAPI.NotifierClient do
  @url "https://onesignal.com/api/v1/notifications"

  def post(data, message) do
    HTTPoison.post(@url, to_payload(data, message), headers())
  end

  defp headers() do
    [
      {"Content-Type", "application/json; charset=utf-8"},
      {"Authorization", "Basic #{Application.fetch_env!(:blockchain_api, :onesignal_rest_api_key)}"}
    ]
  end

  defp to_payload(data, message) do
    %{
      :app_id => Application.fetch_env!(:blockchain_api, :onesignal_app_id),
      :filters => [%{:field => "tag", :key => "address", :relation => "=", :value => data.address}],
      :contents => %{:en => message},
      :data => data
    }
    |> encode()
  end

  defp encode(payload) do
    {:ok, payload} = payload |> Jason.encode()
    payload
  end
end
