defmodule BlockchainAPIWeb.BlockView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.BlockView

  def render("index.json", data) do
    %{
      data: render_many(data.blocks, BlockView, "block.json"),
    }
  end

  def render("show.json", %{block: block}) do
    %{data: render_one(block, BlockView, "block.json")}
  end

  def render("block.json", %{block: block}) do
    block
  end

end
