defmodule BlockchainAPIWeb.AccountPendingTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"account_address" => address}=params) do

    page = Explorer.get_account_pending_transactions(address, params)

    render(conn,
      "index.json",
      account_pending_transactions: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

end
