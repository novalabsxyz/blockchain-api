defmodule BlockchainAPIWeb.GatewayController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    page = Explorer.list_blocks(params)

    render(conn,
      "index.json",
      gateways: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def show(conn, %{"hash" => hash}) do
    gateway = Explorer.get_gateway!(hash)
    render(conn, "show.json", gateway: gateway)
  end
end
