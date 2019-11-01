defmodule BlockchainAPIWeb.HotspotChallengeController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"hotspot_address" => address} = _params) do
    hotspot_challenges =
      address
      |> Util.string_to_bin()
      |> Query.POCRequestTransaction.list_for()

    render(
      conn,
      "index.json",
      hotspot_challenges: hotspot_challenges
    )
  end
end
