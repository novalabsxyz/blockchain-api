defmodule BlockchainAPIWeb.PaymentController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  alias BlockchainAPI.Explorer.Payment

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, _params) do
    payment_transactions = Explorer.list_payment_transactions()
    render(conn, "index.json", payment_transactions: payment_transactions)
  end

  def show(conn, %{"id" => id}) do
    payment = Explorer.get_payment!(id)
    render(conn, "show.json", payment: payment)
  end
end
