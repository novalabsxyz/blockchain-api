defmodule BlockchainAPIWeb.LocationController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    txns = Query.LocationTransaction.list(params)

    render(conn,
      "index.json",
      location_transactions: txns
    )
  end

  def show(conn, %{"hash" => hash}) do
    location = hash
               |> Util.string_to_bin()
               |> Query.LocationTransaction.get!()

    render(conn, "show.json", location: location)
  end
end
