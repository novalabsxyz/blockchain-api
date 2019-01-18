defmodule BlockchainAPIWeb.GatewayLocationView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.GatewayLocationView

  def render("index.json", %{assert_location_transactions: assert_location_transactions}) do
    %{data: render_many(assert_location_transactions, GatewayLocationView, "gateway_location.json")}
  end

  def render("show.json", %{gateway_location: gateway_location}) do
    %{data: render_one(gateway_location, GatewayLocationView, "gateway_location.json")}
  end

  def render("gateway_location.json", %{gateway_location: gateway_location}) do
    %{id: gateway_location.id,
      type: gateway_location.type,
      gateway: gateway_location.gateway,
      owner: gateway_location.owner,
      location: gateway_location.location,
      nonce: gateway_location.nonce,
      fee: gateway_location.fee}
  end
end
