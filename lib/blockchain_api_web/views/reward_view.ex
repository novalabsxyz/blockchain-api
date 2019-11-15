defmodule BlockchainAPIWeb.RewardView do
  use BlockchainAPIWeb, :view

  def render("show.json", %{epoch_rewards: epoch_rewards}) do
    %{data: epoch_rewards}
  end
end
