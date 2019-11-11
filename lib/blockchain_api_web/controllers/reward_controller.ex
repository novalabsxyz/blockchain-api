defmodule BlockchainAPIWeb.HotspotRewardController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  import BlockchainAPI.Cache.CacheService

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"hotspot_address" => address} = params) do
    hotspot_rewards =
      address
      |> Util.string_to_bin()
      |> Query.HotspotReward.list(params)

    conn
    |> put_cache_headers(ttl: :short, key: "block")
    |> render("index.json", hotspot_rewards: hotspot_rewards)
  end
end
