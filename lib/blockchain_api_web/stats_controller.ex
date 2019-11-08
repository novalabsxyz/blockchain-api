defmodule BlockchainAPIWeb.StatsController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPIWeb.StatsView
  alias BlockchainAPI.Query.Stats

  action_fallback BlockchainAPIWeb.FallbackController

  def show(conn, _params) do
    stats = Stats.list()

    conn
    |> put_resp_header("surrogate-control", "max-age=300")
    |> put_view(StatsView)
    |> render("show.json", stats: stats)
  end
end
