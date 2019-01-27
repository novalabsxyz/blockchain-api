defmodule BlockchainAPIWeb.PaymentView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.PaymentView

  def render("index.json", %{payment_transactions: payment_transactions}) do
    %{data: render_many(payment_transactions, PaymentView, "payment.json")}
  end

  def render("show.json", %{payment: payment}) do
    %{data: render_one(payment, PaymentView, "payment.json")}
  end

  def render("payment.json", %{payment: payment}) do
    payment |> Poison.encode!
  end
end
