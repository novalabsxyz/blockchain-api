defmodule BlockchainAPIWeb.GatewayLocationController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  alias BlockchainAPI.Explorer.GatewayLocation

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, _params) do
    assert_location_transactions = Explorer.list_assert_location_transactions()
    render(conn, "index.json", assert_location_transactions: assert_location_transactions)
  end

  def show(conn, %{"id" => id}) do
    gateway_location = Explorer.get_gateway_location!(id)
    render(conn, "show.json", gateway_location: gateway_location)
  end
end
