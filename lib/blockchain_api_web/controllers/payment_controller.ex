defmodule BlockchainAPIWeb.PaymentController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Explorer}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    page = Explorer.list_payment_transactions(params)

    render(conn,
      "index.json",
      payment_transactions: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def show(conn, %{"hash" => hash}) do
    payment = hash
              |> Util.string_to_bin()
              |> Explorer.get_payment!()

    render(conn, "show.json", payment: payment)
  end
end
