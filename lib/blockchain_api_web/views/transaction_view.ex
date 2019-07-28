defmodule BlockchainAPIWeb.TransactionView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.TransactionView

  def render("index.json", data) do
    %{
      data: render_many(data.transactions, TransactionView, "transaction.json")
    }
  end

  def render("show.json", %{transaction: transaction}) do
    %{data: render_one(transaction, TransactionView, "transaction.json")}
  end

  def render("transaction.json", %{transaction: txn}) do
    txn
  end
end
