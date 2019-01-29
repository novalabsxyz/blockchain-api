defmodule BlockchainAPIWeb.TransactionView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.TransactionView

  def render("index.json", %{transactions: transactions}) do
    %{data: render_many(transactions, TransactionView, "transaction.json")}
  end

  def render("show.json", %{transaction: transaction}) do
    %{data: render_one(transaction, TransactionView, "transaction.json")}
  end

  def render("transaction.json", %{transaction: txn}) do
    txn |> Poison.encode!
  end
end
