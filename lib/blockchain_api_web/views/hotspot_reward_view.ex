defmodule BlockchainAPIWeb.HotspotRewardView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.HotspotRewardView

  def render("index.json", data) do
    %{
      data: render_many(data.hotspot_rewards, HotspotRewardView, "hotspot_reward.json")
    }
  end

  def render("show.json", %{hotspot_reward: hotspot_reward}) do
    %{data: render_one(hotspot_reward, HotspotRewardView, "hotspot_reward.json")}
  end

  def render("hotspot_reward.json", %{hotspot_reward: hotspot_reward}) do
    hotspot_reward
  end
end
