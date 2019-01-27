defmodule BlockchainAPIWeb.CoinbaseController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  @default_params %{page: 1, page_size: 10}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) when map_size(params) == 0 do
    coinbase_transactions = Explorer.list_coinbase_transactions(@default_params)
    render(conn, "index.json", coinbase_transactions: coinbase_transactions)
  end

  def show(conn, %{"hash" => hash}) do
    coinbase = Explorer.get_coinbase!(hash)
    render(conn, "show.json", coinbase: coinbase)
  end
end
