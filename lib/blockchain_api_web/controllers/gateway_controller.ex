defmodule BlockchainAPIWeb.GatewayController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    gateways = Query.GatewayTransaction.list(params)

    render(
      conn,
      "index.json",
      gateways: gateways
    )
  end

  def show(conn, %{"hash" => hash}) do
    gateway =
      hash
      |> Util.string_to_bin()
      |> Query.GatewayTransaction.get!()

    render(conn, "show.json", gateway: gateway)
  end
end
