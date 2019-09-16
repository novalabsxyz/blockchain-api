defmodule BlockchainAPIWeb.CoinbaseController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    txns = Query.CoinbaseTransaction.list(params)

    render(
      conn,
      "index.json",
      coinbase_transactions: txns
    )
  end

  def show(conn, %{"hash" => hash}) do
    coinbase =
      hash
      |> Util.string_to_bin()
      |> Query.CoinbaseTransaction.get!()

    render(conn, "show.json", coinbase: coinbase)
  end
end
