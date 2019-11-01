defmodule BlockchainAPIWeb.HotspotChallengeView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.HotspotChallengeView

  def render("index.json", data) do
    %{
      data: render_many(data.hotspot_challenges, HotspotChallengeView, "hotspot_challenge.json")
    }
  end

  def render("show.json", %{hotspot_challenge: challenge}) do
    %{data: render_one(challenge, HotspotChallengeView, "hotspot_challenge.json")}
  end

  def render("hotspot_challenge.json", %{hotspot_challenge: challenge}) do
    challenge
  end
end
