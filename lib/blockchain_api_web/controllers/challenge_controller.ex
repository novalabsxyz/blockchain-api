defmodule BlockchainAPIWeb.ChallengeController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    data = Query.POCReceiptsTransaction.list(params)

    render(conn,
      "index.json",
      challenges: data.challenges,
      total_ongoing: data.total_ongoing,
      issued: data.issued,
      successful: data.successful,
      failed: data.failed
    )
  end

  def show(conn, %{"id" => id}) do
    challenge = Query.POCReceiptsTransaction.show(id)
    render(conn, "show.json", challenge: challenge)
  end

end
