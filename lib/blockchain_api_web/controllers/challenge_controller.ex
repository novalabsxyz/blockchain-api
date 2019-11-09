defmodule BlockchainAPIWeb.ChallengeController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    challenges = Query.POCReceiptsTransaction.list(params)
    total_ongoing = Query.Transaction.get_ongoing_poc_requests()
    issued = Query.POCReceiptsTransaction.issued()
    {successful, failed} = Query.POCReceiptsTransaction.aggregate_challenges(challenges)

    conn
    |> put_resp_header("surrogate-key", "block")
    |> put_resp_header("surrogate-control", "max-age=300")
    |> put_resp_header("cache-control", "max-age=300")
    |> render(
      "index.json",
      challenges: challenges,
      total_ongoing: total_ongoing,
      issued: issued,
      successful: successful,
      failed: failed
    )
  end

  def show(conn, %{"id" => id}) do
    challenge = Query.POCReceiptsTransaction.show(id)

    conn
    |> put_resp_header("surrogate-key", "eternal")
    |> put_resp_header("surrogate-control", "max-age=86400")
    |> put_resp_header("cache-control", "max-age=86400")
    |> render("show.json", challenge: challenge)
  end
end
