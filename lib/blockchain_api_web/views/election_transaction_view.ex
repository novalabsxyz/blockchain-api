defmodule BlockchainAPIWeb.ElectionTransactionView do
  use BlockchainAPIWeb, :view

  alias BlockchainAPIWeb.ElectionTransactionView

  def render("index.json", data) do
    %{data: render_many(data.groups, ElectionTransactionView, "election_transaction_view.json")}
  end

  def render("election_transaction_view.json", %{election_transaction: txn}) do
    txn
  end
end
