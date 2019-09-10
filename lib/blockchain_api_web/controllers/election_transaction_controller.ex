defmodule BlockchainAPIWeb.ElectionTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    elections = Query.ElectionTransaction.list(params)
    render(conn, "index.json", elections: elections)
  end

  def show(conn, %{"hash" => hash}) do
    election =
      case Query.ElectionTransaction.get(hash) do
        nil -> %{}
        election -> election
      end

    render(conn, "show.json", election: election)
  end
end
