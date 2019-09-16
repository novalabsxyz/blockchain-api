defmodule BlockchainAPIWeb.AccountGatewayController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"account_address" => address} = params) do
    account_gateways =
      address
      |> Util.string_to_bin()
      |> Query.AccountTransaction.get_gateways(params)

    render(
      conn,
      "index.json",
      account_gateways: account_gateways
    )
  end
end
