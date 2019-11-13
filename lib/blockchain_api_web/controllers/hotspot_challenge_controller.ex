defmodule BlockchainAPIWeb.HotspotChallengeController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  import BlockchainAPI.Cache.CacheService
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"hotspot_address" => address} = _params) do
    hotspot_challenges =
      address
      |> Util.string_to_bin()
      |> Query.POCRequestTransaction.list_for()

    conn
    |> put_cache_headers(ttl: :short, key: "block")
    |> render("index.json", hotspot_challenges: hotspot_challenges)
  end
end
