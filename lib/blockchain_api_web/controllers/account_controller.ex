defmodule BlockchainAPIWeb.AccountController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, DBManager, Schema.Account}
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    page = DBManager.list_accounts(params)

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
    bin_address = address |> Util.string_to_bin()
    account = bin_address |> DBManager.get_account!() |> Account.encode_model()
    account_balance_history = bin_address |> DBManager.get_account_balance_history()
    account_with_balance = Map.merge(account, %{history: account_balance_history})

    render(conn, "show.json", account: account_with_balance)
  end
end
