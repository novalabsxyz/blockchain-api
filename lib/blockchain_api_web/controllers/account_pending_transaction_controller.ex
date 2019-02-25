defmodule BlockchainAPIWeb.AccountPendingTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Explorer}
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"account_address" => address}=params) do

    page = address
           |> Util.string_to_bin()
           |> Explorer.get_account_pending_transactions(params)

    render(conn,
      "index.json",
      account_pending_transactions: Explorer.get_account_pending_transactions(address)
    )
  end

end
