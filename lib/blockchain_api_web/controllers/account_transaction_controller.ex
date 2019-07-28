defmodule BlockchainAPIWeb.AccountTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"account_address" => address} = params) do
    bin_address = address |> Util.string_to_bin()

    account_txns = bin_address |> Query.AccountTransaction.list(params)

    txns =
      case account_txns do
        [] ->
          # NOTE: This account does not have any transactions ever?
          # Try getting just the pending payment transactions for it
          bin_address |> Query.PendingPayment.get_by_address()

        t ->
          t
      end

    render(
      conn,
      "index.json",
      account_transactions: txns
    )
  end
end
