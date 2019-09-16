defmodule BlockchainAPIWeb.AccountGatewayView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.AccountGatewayView

  def render("index.json", data) do
    %{
      data: render_many(data.account_gateways, AccountGatewayView, "account_gateway.json")
    }
  end

  def render("show.json", %{account_gateway: gateway}) do
    %{data: render_one(gateway, AccountGatewayView, "account_gateway.json")}
  end

  def render("account_gateway.json", %{account_gateway: gateway}) do
    gateway
  end
end
