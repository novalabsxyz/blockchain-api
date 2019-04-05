defmodule BlockchainAPIWeb.HotspotView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.HotspotView

  def render("index.json", data) do
    %{
      data: render_many(data.hotspots, HotspotView, "hotspot.json"),
    }
  end

  def render("show.json", %{hotspot: hotspot}) do
    %{data: render_one(hotspot, HotspotView, "hotspot.json")}
  end

  def render("search.json", data) do
    %{
      data: render_many(data.results, HotspotView, "hotspot.json"),
    }
  end

  def render("hotspot.json", %{hotspot: hotspot}) do
    hotspot
  end
end
