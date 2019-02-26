defmodule BlockchainAPIWeb.CoinbaseController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, DBManager}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    page = DBManager.list_coinbase_transactions(params)

    render(conn,
      "index.json",
      coinbase_transactions: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def show(conn, %{"hash" => hash}) do
    coinbase = hash
               |> Util.string_to_bin()
               |> DBManager.get_coinbase!()

    render(conn, "show.json", coinbase: coinbase)
  end

end
