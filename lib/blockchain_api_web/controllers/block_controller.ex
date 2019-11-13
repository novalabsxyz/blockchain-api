defmodule BlockchainAPIWeb.BlockController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query
  import BlockchainAPI.Cache.CacheService

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    blocks = Query.Block.list(params)

    conn
    |> put_cache_headers(ttl: :short, key: "block")
    |> render("index.json", blocks: blocks)
  end

  def show(conn, %{"height" => height}) do
    block = Query.Block.get(height)
    conn
    |> put_cache_headers(ttl: :long, key: "eternal")
    |> render("show.json", block: block)
  end
end
