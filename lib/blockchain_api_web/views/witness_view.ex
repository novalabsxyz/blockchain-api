defmodule BlockchainAPIWeb.WitnessView do
  use BlockchainAPIWeb, :view

  def render("show.json", %{witnesses: witnesses}) do
    %{data: witnesses}
  end
end
