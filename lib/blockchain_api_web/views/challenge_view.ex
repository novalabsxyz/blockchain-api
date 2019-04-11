defmodule BlockchainAPIWeb.ChallengeView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.ChallengeView

  def render("index.json", data) do
    %{
      data: render_many(data.challenges, ChallengeView, "challenge.json"),
    }
  end

  def render("show.json", %{challenge: challenge}) do
    %{data: render_one(challenge, ChallengeView, "challenge.json")}
  end

  def render("challenge.json", %{challenge: challenge}) do
    challenge
  end
end
