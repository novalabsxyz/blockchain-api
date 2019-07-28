defmodule BlockchainAPIWeb.LocationView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.LocationView

  def render("index.json", data) do
    %{
      data: render_many(data.location_transactions, LocationView, "location.json")
    }
  end

  def render("show.json", %{location: location}) do
    %{data: render_one(location, LocationView, "location.json")}
  end

  def render("location.json", %{location: location}) do
    location
  end
end
