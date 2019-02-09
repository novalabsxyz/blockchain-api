defmodule BlockchainAPIWeb.BlockView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.BlockView

  def render("index.json", page) do
    %{
      data: render_many(page.blocks, BlockView, "block.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("show.json", %{block: block}) do
    %{data: render_one(block, BlockView, "block.json")}
  end

  def render("block.json", %{block: block}) do
    block
  end

end
