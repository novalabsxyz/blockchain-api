defmodule BlockchainAPIWeb.ElectionTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    elections = Query.ElectionTransaction.list(params)
    conn
    |> put_resp_header("surrogate-key", "block")
    |> put_resp_header("surrogate-control", "max-age=300")
    |> put_resp_header("cache-control", "max-age=300")
    |> render("index.json", elections: elections)
  end

  def show(conn, %{"hash" => hash}) do
    election =
      case Query.ElectionTransaction.get_consensus_group(hash) do
        nil -> %{}
        election -> election
      end

    conn
    |> put_resp_header("surrogate-key", "block")
    |> put_resp_header("surrogate-control", "max-age=300")
    |> put_resp_header("cache-control", "max-age=300")
    |> render("show.json", election: election)
  end
end
