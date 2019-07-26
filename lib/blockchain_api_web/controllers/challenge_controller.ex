defmodule BlockchainAPIWeb.ChallengeController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Query, Util}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    challenges = Query.POCReceiptsTransaction.challenges(params)
    ongoing = Query.POCRequestTransaction.ongoing(params)

    start = Timex.now() |> Timex.shift(hours: -24) |> Timex.to_unix()
    finish = Util.current_time()
    {successful, failed} =
      challenges
      |> Enum.filter(fn challenge ->
        challenge.time >= start && challenge.time <= finish
      end)
      |> Enum.reduce({0, 0}, fn c, {successful, failed} ->
        if c.success == true do
          {successful + 1, failed}
        else
          {successful, failed + 1}
        end
      end)
    issued = successful + failed

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
