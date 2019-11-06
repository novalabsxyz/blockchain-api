defmodule BlockchainAPIWeb.SecExchangeView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.SecExchangeView

  def render("index.json", data) do
    IO.inspect(data, label: :data)
    %{
      data: render_many(data.sec_exchange_transactions, SecExchangeView, "sec_exchange.json")
    }
  end

  def render("show.json", %{sec_exchange: sec_exchange}) do
    %{data: render_one(sec_exchange, SecExchangeView, "sec_exchange.json")}
  end

  def render("sec_exchange.json", %{sec_exchange: sec_exchange}) do
    sec_exchange
  end
end
