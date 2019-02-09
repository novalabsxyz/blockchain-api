defmodule BlockchainAPIWeb.LocationView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.LocationView

  def render("index.json", page) do
    %{
      data: render_many(page.location_transactions, LocationView, "location.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("show.json", page) do
    %{
      data: render_one(page.location_transactions, LocationView, "location.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end


  def render("location.json", %{location: location}) do
    location
  end
end
