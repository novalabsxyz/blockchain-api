defmodule BlockchainAPIWeb.PaymentView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.PaymentView

  def render("index.json", data) do
    %{
      data: render_many(data.payment_transactions, PaymentView, "payment.json"),
    }
  end

  def render("show.json", %{payment: payment}) do
    %{data: render_one(payment, PaymentView, "payment.json")}
  end

  def render("payment.json", %{payment: payment}) do
    payment
  end
end
