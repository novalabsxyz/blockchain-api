defmodule BlockchainAPIWeb.StatsView do
  use BlockchainAPIWeb, :view

  def render("show.json", %{stats: stats}) do
    %{data: stats}
  end
end
