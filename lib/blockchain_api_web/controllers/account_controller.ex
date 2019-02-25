defmodule BlockchainAPIWeb.AccountController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Explorer}
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    page = Explorer.list_accounts(params)

    render(conn,
      "index.json",
      accounts: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def show(conn, %{"address" => address}) do
    account = address
              |> Util.string_to_bin()
              |> Explorer.get_account!()

    render(conn, "show.json", account: account)
  end

end
