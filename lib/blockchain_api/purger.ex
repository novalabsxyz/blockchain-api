defmodule BlockchainAPI.Purger do
  def purge_key(key) do
    fastly_post("purge/#{key}")
  end

  defp fastly_post(path, body \\ "") do
    api_key = Application.get_env(:blockchain_api, :fastly_api_key)
    service_id = Application.get_env(:blockchain_api, :fastly_service_id)

    if api_key && service_id do
      url = "https://api.fastly.com/service/#{service_id}/#{path}"

      response = HTTPoison.post(url, body, [{"Fastly-Key", api_key}])
      IO.inspect(response)
      response
    end
  end
end
