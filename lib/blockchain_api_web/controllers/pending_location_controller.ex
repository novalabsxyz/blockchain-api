defmodule BlockchainAPIWeb.PendingLocationController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  alias BlockchainAPIWeb.LocationView

  action_fallback BlockchainAPIWeb.FallbackController

  def show(conn, %{"gateway" => gateway, "owner" => owner, "nonce" => nonce} = _params) do
    pending_location =
      Query.PendingLocation.get(Util.string_to_bin(owner), Util.string_to_bin(gateway), nonce)

    conn
    |> put_view(LocationView)
    |> render("show.json", location: pending_location)
  end
end
