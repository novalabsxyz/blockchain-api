defmodule BlockchainAPIWeb.BlockController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    page = Query.Block.list_blocks(params)

    render(conn,
      "index.json",
      blocks: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def show(conn, %{"height" => height}) do
    block = Query.Block.get_block!(height)
    render(conn, "show.json", block: block)
  end

end
