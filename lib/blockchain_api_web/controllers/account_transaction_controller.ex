defmodule BlockchainAPIWeb.AccountTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"account_address" => address}=params) do

    bin_address = address |> Util.string_to_bin()

    account_txns = bin_address |> Query.AccountTransaction.get(params)

    # TODO: This really needs to be in a view with some complicated join involved
    # Since doing this _would_ give false positives when a pending_txn is way before where
    # the current account txns are.
    # NOTE: If txn has already appeared in account_txns then remove it from pending_transactions list
    pending_txns =
      bin_address
      |> Query.Account.get_pending_transactions()
      |> Enum.reject(fn p -> Enum.any?(account_txns, fn t -> t.hash == p.hash end) end)

    total_txns = pending_txns ++ account_txns

    txns =
      case total_txns do
        [] ->
          # NOTE: This account does not have any transactions ever?
          # Try getting just the pending payment transactions for it?
          bin_address
          |> Query.PendingPayment.get_by_address()
        t -> t
      end

    render(conn,
      "index.json",
      account_transactions: txns
    )
  end
end
