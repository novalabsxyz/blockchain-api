defmodule BlockchainAPIWeb.CoinbaseView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.CoinbaseView

  def render("index.json", page) do
    %{
      data: render_many(page.coinbase_transactions, CoinbaseView, "coinbase.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("show.json", page) do
    %{
      data: render_one(page.coinbase_transactions, CoinbaseView, "coinbase.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("coinbase.json", %{coinbase: coinbase}) do
    coinbase
  end

end
