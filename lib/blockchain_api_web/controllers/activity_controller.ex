defmodule BlockchainAPIWeb.ActivityController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"hotspot_address" => address}=params) do
    activity = address
               |> Util.string_to_bin()
               |> Query.HotspotActivity.activity_for(params)

    render(conn,
      "index.json",
      activity: activity
    )
  end
end
