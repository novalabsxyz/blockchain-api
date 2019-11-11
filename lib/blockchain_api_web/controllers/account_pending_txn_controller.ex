defmodule BlockchainAPIWeb.AccountPendingTxnController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"account_address" => address} = params) do
    pending_txns = address
                   |> Util.string_to_bin()
                   |> Query.AccountPendingTxn.list(params)

    render(
      conn,
      "index.json",
      account_pending_txns: pending_txns
    )
  end
end
