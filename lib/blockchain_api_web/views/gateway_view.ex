defmodule BlockchainAPIWeb.GatewayView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.GatewayView

  def render("index.json", page) do
    %{
      data: render_many(page.gateways, GatewayView, "gateway.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("show.json", %{gateway: gateway}) do
    %{data: render_one(gateway, GatewayView, "gateway.json")}
  end

  def render("gateway.json", %{gateway: gateway}) do
    gateway
  end
end
