defmodule BlockchainAPIWeb.AccountPendingTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"account_address" => address}=_params) do
    render(conn,
      "index.json",
      account_pending_transactions: Explorer.get_account_pending_transactions(address)
    )
  end

end
