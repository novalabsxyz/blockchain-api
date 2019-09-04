defmodule BlockchainAPIWeb.HotspotController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Query, Util}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    hotspots = Query.Hotspot.list(params)

    render(conn,
      "index.json",
      hotspots: hotspots
    )
  end

  def show(conn, %{"address" => address}) do
    hotspot =
      with address <- Util.string_to_bin(address),
           hotspot when not is_nil(hotspot) <- Query.Hotspot.get(address) do
        hotspot
      else
        _ -> %{}
      end

    render(conn, "show.json", hotspot: hotspot)
  end

  def search(conn, %{"term" => term}=_params) do
    results = Query.Hotspot.search(term)

    render(conn,
      "search.json",
      results: results
    )
  end
end
