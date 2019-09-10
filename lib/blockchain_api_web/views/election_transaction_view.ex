defmodule BlockchainAPIWeb.ElectionTransactionView do
  use BlockchainAPIWeb, :view

  alias BlockchainAPIWeb.ElectionTransactionView

  def render("index.json", data) do
    %{data: render_many(data.elections, ElectionTransactionView, "election_transaction.json")}
  end

  def render("show.json", %{election: election}) do
    %{data: render_one(election, ElectionTransactionView, "election_transaction.json")}
  end

  def render("election_transaction.json", %{election_transaction: txn}) do
    txn
  end
end
