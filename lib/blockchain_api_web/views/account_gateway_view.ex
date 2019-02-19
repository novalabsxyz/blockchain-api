defmodule BlockchainAPIWeb.AccountGatewayView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.AccountGatewayView

  def render("index.json", page) do
    %{
      data: render_many(page.account_gateways, AccountGatewayView, "account_gateway.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("show.json", %{account_gateway: gateway}) do
    %{data: render_one(gateway, AccountGatewayView, "account_gateway.json")}
  end

  def render("account_gateway.json", %{account_gateway: gateway}) do
    gateway
  end

end
