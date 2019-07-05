defmodule BlockchainAPIWeb.FourOhFourController do
  use BlockchainAPIWeb, :controller

  def index(conn, _params) do
    conn
    |> put_status(:not_found)
    |> put_view(BlockchainAPIWeb.ErrorView)
    |> render("404.json")
  end
end
