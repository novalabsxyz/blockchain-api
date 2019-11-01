defmodule BlockchainAPIWeb.AccountRewardController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"account_address" => address} = _params) do
    account_rewards = address
                      |> Util.string_to_bin()
                      |> Query.RewardsTransaction.list_for()

    render(
      conn,
      "index.json",
      account_rewards: account_rewards
    )
  end
end
