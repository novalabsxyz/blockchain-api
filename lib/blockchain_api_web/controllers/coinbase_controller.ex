defmodule BlockchainAPIWeb.CoinbaseController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, _params) do
    coinbase_transactions = Explorer.list_coinbase_transactions()
    render(conn, "index.json", coinbase_transactions: coinbase_transactions)
  end

  def show(conn, %{"height" => height}) do
    coinbase = Explorer.get_coinbase!(height)
    render(conn, "show.json", coinbase: coinbase)
  end
end
