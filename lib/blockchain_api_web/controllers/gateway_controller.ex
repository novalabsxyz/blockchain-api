defmodule BlockchainAPIWeb.GatewayController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    page = Query.GatewayTransaction.list(params)

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
    gateway = hash
              |> Util.string_to_bin()
              |> Query.GatewayTransaction.get!()

    render(conn, "show.json", gateway: gateway)
  end
end
