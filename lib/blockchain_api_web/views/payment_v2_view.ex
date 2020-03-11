defmodule BlockchainAPIWeb.PaymentV2View do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.PaymentV2View

  def render("index.json", data) do
    %{
      data: render_many(data.payment_transactions, PaymentV2View, "payment_v2.json")
    }
  end

  def render("show.json", %{payment_v2: payment_v2}) do
    %{data: render_one(payment_v2, PaymentV2View, "payment_v2.json")}
  end

  def render("payment_v2.json", %{payment_v2: payment_v2}) do
    payment_v2
  end
end
