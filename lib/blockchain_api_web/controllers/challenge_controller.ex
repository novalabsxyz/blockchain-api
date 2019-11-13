defmodule BlockchainAPIWeb.ChallengeController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query
  import BlockchainAPI.Cache.CacheService

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    challenges = Query.POCReceiptsTransaction.list(params)
    total_ongoing = Query.Transaction.get_ongoing_poc_requests()
    issued = Query.POCReceiptsTransaction.issued()
    {successful, failed} = Query.POCReceiptsTransaction.aggregate_challenges(challenges)

    conn
    |> put_cache_headers(ttl: :short, key: "block")
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
    |> put_cache_headers(ttl: :long, key: "eternal")
    |> render("show.json", challenge: challenge)
  end
end
