defmodule BlockchainAPI.Cache.CacheService do
  import Plug.Conn

  def purge_key(key) do
    fastly_post("purge/#{key}")
  end

  def put_cache_headers(%Plug.Conn{params: %{"before" => _, "limit" => _}} = conn, _opts) do
    IO.puts("override with pagination cache headers")
    conn
    |> do_put_cache_headers(ttl: :long, key: "pagination")
  end

  def put_cache_headers(conn, options) do
    conn
    |> do_put_cache_headers(options)
  end

  defp do_put_cache_headers(conn, ttl: ttl, key: key) do
    conn
    |> put_resp_header("surrogate-key", key)
    |> do_put_cache_headers(ttl: ttl)
  end

  defp do_put_cache_headers(conn, ttl: ttl) do
    ttl = get_ttl_value(ttl)

    conn
    |> put_resp_header("surrogate-control", "max-age=#{ttl}")
    |> put_resp_header("cache-control", "max-age=#{ttl}")
  end

  defp get_ttl_value(ttl) do
    case ttl do
      :never -> 0
      :short -> 300   # 5 minutes
      :medium -> 600  # 10 minutes
      :long -> 86_400 # 1 day
    end
  end

  defp fastly_post(path, body \\ "") do
    api_key = Application.get_env(:blockchain_api, :fastly_api_key)
    service_id = Application.get_env(:blockchain_api, :fastly_service_id)

    if api_key && service_id do
      url = "https://api.fastly.com/service/#{service_id}/#{path}"
      HTTPoison.post(url, body, [{"Fastly-Key", api_key}])
    end
  end
end
