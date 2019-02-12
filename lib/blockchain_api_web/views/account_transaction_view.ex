defmodule BlockchainAPIWeb.AccountTransactionView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.AccountTransactionView

  def render("index.json", page) do
    %{
      data: render_many(page.account_transactions, AccountTransactionView, "account_transaction.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("show.json", %{account_transaction: txn}) do
    %{data: render_one(txn, AccountTransactionView, "account_transaction.json")}
  end

  def render("account_transaction.json", %{account_transaction: txn}) do
    txn
  end

end
