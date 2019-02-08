defmodule BlockchainAPIWeb.GatewayController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  @default_params %{page: 1, page_size: 10}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) when map_size(params) == 0 do
    add_gateway_transactions = Explorer.list_gateway_transactions(@default_params)
    render(conn, "index.json", add_gateway_transactions: add_gateway_transactions)
  end
  def index(conn, params) do
    add_gateway_transactions = Explorer.list_gateway_transactions(params)
    render(conn, "index.json", add_gateway_transactions: add_gateway_transactions)
  end

  def show(conn, %{"hash" => hash}) do
    gateway = Explorer.get_gateway!(hash)
    render(conn, "show.json", gateway: gateway)
  end
end
