defmodule BlockchainAPIWeb.RewardsView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.RewardsView

  def render("index.json", data) do
    %{
      data: render_many(data.rewards, RewardsView, "rewards.json"),
    }
  end

  def render("show.json", %{rewards: rewards}) do
    %{data: render_one(rewards, RewardsView, "rewards.json")}
  end

  def render("rewards.json", %{rewards: rewards}) do
    rewards
  end
end
