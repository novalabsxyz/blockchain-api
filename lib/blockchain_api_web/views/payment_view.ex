defmodule BlockchainAPIWeb.PaymentView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.PaymentView

  def render("index.json", page) do
    %{
      data: render_many(page.payment_transactions, PaymentView, "payment.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("show.json", page) do
    %{
      data: render_one(page.payment_transactions, PaymentView, "payment.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("payment.json", %{payment: payment}) do
    payment
  end
end
