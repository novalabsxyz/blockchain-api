defmodule BlockchainAPIWeb.RewardsController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  alias BlockchainAPIWeb.RewardView

  action_fallback BlockchainAPIWeb.FallbackController

  def show(conn, %{"hash" => hash} = _params) do
    epoch_rewards =
      hash
      |> Util.string_to_bin()
      |> Query.RewardTxn.total_by_epoch()

    res =
      case epoch_rewards do
        nil ->
          0
        x ->
          Decimal.to_integer(x)
      end

    conn
    |> put_view(RewardView)
    |> render("show.json", epoch_rewards: res)
  end
end
