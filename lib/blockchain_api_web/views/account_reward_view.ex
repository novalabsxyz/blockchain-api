defmodule BlockchainAPIWeb.AccountRewardView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.AccountRewardView

  def render("index.json", data) do
    %{
      data: render_many(data.account_rewards, AccountRewardView, "account_reward.json")
    }
  end

  def render("show.json", %{account_reward: reward}) do
    %{data: render_one(reward, AccountRewardView, "account_reward.json")}
  end

  def render("account_reward.json", %{account_reward: reward}) do
    reward
  end
end
