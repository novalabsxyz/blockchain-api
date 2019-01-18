defmodule BlockchainAPIWeb.GatewayView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.GatewayView

  def render("index.json", %{add_gateway_transactions: add_gateway_transactions}) do
    %{data: render_many(add_gateway_transactions, GatewayView, "gateway.json")}
  end

  def render("show.json", %{gateway: gateway}) do
    %{data: render_one(gateway, GatewayView, "gateway.json")}
  end

  def render("gateway.json", %{gateway: gateway}) do
    %{id: gateway.id,
      type: gateway.type,
      owner: gateway.owner,
      gateway: gateway.gateway}
  end
end
