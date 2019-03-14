defmodule BlockchainAPIWeb.PaymentController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    page = Query.PaymentTransaction.list(params)

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
              |> Query.PaymentTransaction.get!()

    render(conn, "show.json", payment: payment)
  end
end
