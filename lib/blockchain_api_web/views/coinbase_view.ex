defmodule BlockchainAPIWeb.CoinbaseView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.CoinbaseView

  def render("index.json", %{coinbase_transactions: coinbase_transactions}) do
    %{data: render_many(coinbase_transactions, CoinbaseView, "coinbase.json")}
  end

  def render("show.json", %{coinbase: coinbase}) do
    %{data: render_one(coinbase, CoinbaseView, "coinbase.json")}
  end

  def render("coinbase.json", %{coinbase: coinbase}) do
    %{id: coinbase.id,
      type: coinbase.type,
      amount: coinbase.amount,
      payee: coinbase.payee}
  end
end