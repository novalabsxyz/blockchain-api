defmodule BlockchainAPIWeb.BlockController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    blocks = Query.Block.list(params)

    conn
    |> put_resp_header("surrogate-key", "block")
    |> put_resp_header("surrogate-control", "max-age=300")
    |> put_resp_header("cache-control", "max-age=300")
    |> render(
      "index.json",
      blocks: blocks
    )
  end

  def show(conn, %{"height" => height}) do
    block = Query.Block.get(height)
    conn
    |> put_resp_header("surrogate-key", "eternal")
    |> put_resp_header("surrogate-control", "max-age=86400")
    |> put_resp_header("cache-control", "max-age=86400")
    |> render("show.json", block: block)
  end
end
