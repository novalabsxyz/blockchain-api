defmodule BlockchainAPIWeb.LocationController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  @default_params %{page: 1, page_size: 10}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) when map_size(params) == 0 do
    location_transactions = Explorer.list_location_transactions(@default_params)
    render(conn, "index.json", location_transactions: location_transactions)
  end
  def index(conn, params) do
    location_transactions = Explorer.list_location_transactions(params)
    render(conn, "index.json", location_transactions: location_transactions)
  end

  def show(conn, %{"hash" => hash}) do
    location = Explorer.get_location!(hash)
    render(conn, "show.json", location: location)
  end
end
