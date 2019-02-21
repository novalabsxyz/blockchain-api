defmodule BlockchainAPIWeb.AccountPendingTransactionView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.AccountPendingTransactionView

  def render("index.json", page) do
    %{
      data: render_many(page.account_pending_transactions, AccountPendingTransactionView, "account_pending_transaction.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("show.json", %{account_pending_transaction: account_pending_transaction}) do
    %{data: render_one(account_pending_transaction, AccountPendingTransactionView, "account_pending_transaction.json")}
  end

  def render("account_pending_transaction.json", %{account_pending_transaction: account_pending_transaction}) do
    account_pending_transaction
  end

end
