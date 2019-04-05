defmodule BlockchainAPIWeb.AccountTransactionView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.AccountTransactionView

  def render("index.json", data) do
    %{
      data: render_many(data.account_transactions, AccountTransactionView, "account_transaction.json"),
    }
  end

  def render("show.json", %{account_transaction: txn}) do
    %{data: render_one(txn, AccountTransactionView, "account_transaction.json")}
  end

  def render("account_transaction.json", %{account_transaction: txn}) do
    txn
  end

end
