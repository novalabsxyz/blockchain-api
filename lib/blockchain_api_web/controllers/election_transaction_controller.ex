defmodule BlockchainAPIWeb.ElectionTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query
  import BlockchainAPI.Cache.CacheService

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    elections = Query.ElectionTransaction.list(params)
    conn
    |> put_cache_headers(ttl: :short, key: "block")
    |> render("index.json", elections: elections)
  end

  def show(conn, %{"hash" => hash}) do
    election =
      case Query.ElectionTransaction.get_consensus_group(hash) do
        nil -> %{}
        election -> election
      end

    conn
    |> put_cache_headers(ttl: :short, key: "block")
    |> render("show.json", election: election)
  end
end
