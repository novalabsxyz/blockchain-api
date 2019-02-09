defmodule BlockchainAPIWeb.AccountTransactionView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.AccountTransactionView

  def render("index.json", %{account_transactions: account_transactions}) do
    %{data: render_many(account_transactions, AccountTransactionView, "account_transaction.json")}
  end

  def render("show.json", %{account_transaction: account_transaction}) do
    %{data: render_one(account_transaction, AccountTransactionView, "account_transaction.json")}
  end

  def render("account_transaction.json", %{account_transaction: txn}) do
    txn
  end

end
