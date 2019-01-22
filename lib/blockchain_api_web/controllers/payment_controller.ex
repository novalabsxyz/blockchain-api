defmodule BlockchainAPIWeb.PaymentController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer

  action_fallback BlockchainAPIWeb.FallbackController

  def show(conn, %{"hash" => hash}) do
    payment = Explorer.get_payment!(hash)
    render(conn, "show.json", payment: payment)
  end
end
