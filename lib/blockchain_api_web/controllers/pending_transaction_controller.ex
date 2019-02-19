defmodule BlockchainAPIWeb.PendingTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    page = Explorer.list_pending_transactions(params)

    render(conn,
      "index.json",
      pending_transactions: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def show(conn, %{"hash" => hash}) do
    pending_txn = Explorer.get_pending_transaction!(hash)
    render(conn, "show.json", pending_txn: pending_txn)
  end
end
