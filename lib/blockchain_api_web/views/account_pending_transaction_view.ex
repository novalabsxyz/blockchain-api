defmodule BlockchainAPIWeb.AccountPendingTransactionView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.AccountPendingTransactionView

  def render("index.json", page) do
    %{
      data: render_many(page.account_pending_transactions, AccountPendingTransactionView, "account_pending_transaction.json"),
    }
  end

  def render("show.json", %{account_pending_transaction: account_pending_transaction}) do
    %{data: render_one(account_pending_transaction, AccountPendingTransactionView, "account_pending_transaction.json")}
  end

  def render("account_pending_transaction.json", %{account_pending_transaction: account_pending_transaction}) do
    account_pending_transaction
  end

end
