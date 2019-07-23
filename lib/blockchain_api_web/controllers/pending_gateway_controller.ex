defmodule BlockchainAPIWeb.PendingGatewayController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  alias BlockchainAPIWeb.GatewayView

  action_fallback BlockchainAPIWeb.FallbackController

  def show(conn, %{"gateway" => gateway, "owner" => owner}=_params) do
    pending_gateway = Query.PendingGateway.get(Util.string_to_bin(owner), Util.string_to_bin(gateway))
    conn
    |> put_view(GatewayView)
    |> render("show.json", gateway: pending_gateway)
  end
end
