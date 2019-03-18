defmodule BlockchainAPIWeb.AccountTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"account_address" => address}=params) do

    bin_address = address |> Util.string_to_bin()

    page = bin_address |> Query.AccountTransaction.get(params)
    account_txns = page.entries

    # If txn has already appeared in account_txns then remove it from pending_transactions list
    pending_txns =
      bin_address
      |> Query.Account.get_pending_transactions()
      |> Enum.reject(fn p -> Enum.any?(account_txns, fn t -> t.hash == p.hash end) end)

    total_txns = pending_txns ++ account_txns

    render(conn,
      "index.json",
      account_transactions: total_txns,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end
end
