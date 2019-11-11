defmodule BlockchainAPIWeb.CoinbaseController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  import BlockchainAPI.Cache.CacheService

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    txns = Query.CoinbaseTransaction.list(params)

    conn
    |> put_cache_headers(ttl: :long, key: "eternal")
    |> render("index.json", coinbase_transactions: txns)
  end

  def show(conn, %{"hash" => hash}) do
    coinbase =
      hash
      |> Util.string_to_bin()
      |> Query.CoinbaseTransaction.get!()

    conn
    |> put_cache_headers(ttl: :long, key: "eternal")
    |> render("show.json", coinbase: coinbase)
  end
end
