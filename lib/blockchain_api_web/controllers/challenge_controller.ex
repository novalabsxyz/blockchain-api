defmodule BlockchainAPIWeb.ChallengeController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    challenges = Query.POCReceiptsTransaction.challenges(params)
    ongoing = Query.POCRequestTransaction.ongoing(params)
    aggregated = Query.POCReceiptsTransaction.challenges_twenty_four_hrs(params)

    {issued, successful, failed} =
      case aggregated do
        map when map_size(map) > 0 ->
          {map.issued, map.successful, map.failed}
        _ ->
          {0, 0, 0}
      end

    render(conn,
      "index.json",
      challenges: challenges,
      total_ongoing: ongoing,
      issued: issued,
      successful: successful,
      failed: failed
    )
  end

  def show(conn, %{"id" => id}) do
    challenge = Query.POCReceiptsTransaction.show!(id)
    render(conn, "show.json", challenge: challenge)
  end

end
