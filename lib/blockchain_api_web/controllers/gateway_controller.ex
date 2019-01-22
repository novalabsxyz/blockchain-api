defmodule BlockchainAPIWeb.GatewayController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, _params) do
    add_gateway_transactions = Explorer.list_gateway_transactions()
    render(conn, "index.json", add_gateway_transactions: add_gateway_transactions)
  end

  def show(conn, %{"id" => id}) do
    gateway = Explorer.get_gateway!(id)
    render(conn, "show.json", gateway: gateway)
  end
end
