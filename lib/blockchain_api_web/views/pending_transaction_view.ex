defmodule BlockchainAPIWeb.PendingTransactionView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.PendingTransactionView

  def render("index.json", page) do
    %{
      data: render_many(page.pending_transactions, PendingTransactionView, "pending_transaction.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("show.json", %{pending_txn: pending_txn}) do
    %{data: render_one(pending_txn, PendingTransactionView, "pending_transaction.json")}
  end

  def render("pending_transaction.json", %{pending_txn: pending_txn}) do
    pending_txn
  end

end
