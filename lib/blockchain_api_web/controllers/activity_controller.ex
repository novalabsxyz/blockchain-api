defmodule BlockchainAPIWeb.ActivityController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}

  import BlockchainAPI.Cache.CacheService

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"hotspot_address" => address} = params) do
    activity =
      address
      |> Util.string_to_bin()
      |> Query.HotspotActivity.list(params)

    conn
    |> put_cache_headers(ttl: :short, key: "block")
    |> render("index.json", activity: activity)
  end
end
