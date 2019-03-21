defmodule BlockchainAPIWeb.HotspotView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.HotspotView

  def render("index.json", page) do
    %{
      data: render_many(page.hotspots, HotspotView, "hotspot.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
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
