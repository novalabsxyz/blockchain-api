defmodule BlockchainAPIWeb.LocationController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  import BlockchainAPI.Cache.CacheService

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    txns = Query.LocationTransaction.list(params)

    conn
    |> put_cache_headers(ttl: :short, key: "block")
    |> render("index.json", location_transactions: txns)
  end

  def show(conn, %{"hash" => hash}) do
    location =
      hash
      |> Util.string_to_bin()
      |> Query.LocationTransaction.get!()

    conn
    |> put_cache_headers(ttl: :long, key: "eternal")
    |> render("show.json", location: location)
  end
end
