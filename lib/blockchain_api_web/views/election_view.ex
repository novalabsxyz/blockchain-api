defmodule BlockchainAPIWeb.ElectionView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.ElectionView

  def render("index.json", data) do
    %{
      data: render_many(data.election_transactions, ElectionView, "election.json"),
    }
  end

  def render("show.json", %{election: election}) do
    %{data: render_one(election, ElectionView, "election.json")}
  end

  def render("election.json", %{election: election}) do
    election
  end
end
