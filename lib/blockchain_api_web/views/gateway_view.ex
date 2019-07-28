defmodule BlockchainAPIWeb.GatewayView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.GatewayView

  def render("index.json", data) do
    %{
      data: render_many(data.gateways, GatewayView, "gateway.json")
    }
  end

  def render("show.json", %{gateway: gateway}) do
    %{data: render_one(gateway, GatewayView, "gateway.json")}
  end

  def render("gateway.json", %{gateway: gateway}) do
    gateway
  end
end
