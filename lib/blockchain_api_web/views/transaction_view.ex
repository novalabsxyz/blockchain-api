defmodule BlockchainAPIWeb.TransactionView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.TransactionView

  def render("index.json", page) do
    %{
      data: render_many(page.transactions, TransactionView, "transaction.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("show.json", %{transaction: transaction}) do
    %{data: render_one(transaction, TransactionView, "transaction.json")}
  end

  def render("transaction.json", %{transaction: txn}) do
    txn
  end
end
