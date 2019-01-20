defmodule BlockchainAPIWeb.LocationController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  # alias BlockchainAPI.Explorer.GatewayLocation

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, _params) do
    location_transactions = Explorer.list_location_transactions()
    render(conn, "index.json", location_transactions: location_transactions)
  end

  def show(conn, %{"id" => id}) do
    location = Explorer.get_location!(id)
    render(conn, "show.json", location: location)
  end
end
