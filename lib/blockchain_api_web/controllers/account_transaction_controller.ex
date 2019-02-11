defmodule BlockchainAPIWeb.AccountTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  require Logger
  @default_params %{page: 1, page_size: 10}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"account_address" => address}) do

    page = Explorer.get_account_transactions(address, @default_params)

    IO.inspect page.entries

    render(conn,
      "index.json",
      account_transactions: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def index(conn, %{"account_address" => address, "page" => page, "page_size" => page_size}) do

    page = Explorer.get_account_transactions(address, %{page: String.to_integer(page), page_size: String.to_integer(page_size)})

    render(conn,
      "index.json",
      account_transactions: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

end
