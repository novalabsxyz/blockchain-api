defmodule BlockchainAPIWeb.PendingPaymentController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  alias BlockchainAPIWeb.PaymentView

  action_fallback BlockchainAPIWeb.FallbackController

  def show(conn, %{"payer" => payer, "nonce" => nonce} = _params) do
    pending_payment = Query.PendingPayment.get(Util.string_to_bin(payer), nonce)

    conn
    |> put_view(PaymentView)
    |> render("show.json", payment: pending_payment)
  end
end
