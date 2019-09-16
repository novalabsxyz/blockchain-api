defmodule BlockchainAPIWeb.PaymentController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    txns = Query.PaymentTransaction.list(params)

    render(
      conn,
      "index.json",
      payment_transactions: txns
    )
  end

  def show(conn, %{"hash" => hash}) do
    payment =
      hash
      |> Util.string_to_bin()
      |> Query.PaymentTransaction.get!()

    render(conn, "show.json", payment: payment)
  end
end
