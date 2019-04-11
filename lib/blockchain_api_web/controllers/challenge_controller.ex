defmodule BlockchainAPIWeb.ChallengeController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    challenges = Query.POCReceiptsTransaction.challenges(params)
    ongoing = Query.POCRequestTransaction.ongoing(params)
    completed = Query.POCReceiptsTransaction.completed(params)

    render(conn,
      "index.json",
      challenges: challenges,
      total_ongoing: ongoing,
      total_completed: completed
    )
  end

end
