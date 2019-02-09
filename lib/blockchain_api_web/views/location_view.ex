defmodule BlockchainAPIWeb.LocationView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.LocationView

  def render("index.json", %{location_transactions: location_transactions}) do
    %{data: render_many(location_transactions, LocationView, "location.json")}
  end

  def render("show.json", %{location: location}) do
    %{data: render_one(location, LocationView, "location.json")}
  end

  def render("location.json", %{location: location}) do
    location
  end
end
