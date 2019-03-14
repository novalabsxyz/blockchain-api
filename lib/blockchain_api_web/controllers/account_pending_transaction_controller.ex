defmodule BlockchainAPIWeb.AccountPendingTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"account_address" => address}=_params) do

    account_pending_transactions = address
                                   |> Util.string_to_bin()
                                   |> Query.Account.get_account_pending_transactions()

    render(conn,
      "index.json",
      account_pending_transactions: account_pending_transactions
    )
  end

end
