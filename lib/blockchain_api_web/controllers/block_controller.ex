defmodule BlockchainAPIWeb.BlockController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    blocks = Query.Block.list(params)

    render(conn,
      "index.json",
      blocks: blocks
    )
  end

  def show(conn, %{"height" => height}) do
    block = Query.Block.get(height)
    render(conn, "show.json", block: block)
  end
end
