defmodule BlockchainAPIWeb.LocationController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    page = Query.LocationTransaction.list_location_transactions(params)

    render(conn,
      "index.json",
      location_transactions: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def show(conn, %{"hash" => hash}) do
    location = hash
               |> Util.string_to_bin()
               |> Query.LocationTransaction.get_location!()

    render(conn, "show.json", location: location)
  end
end
