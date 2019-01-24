defmodule BlockchainAPIWeb.AccountController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{}) do
    render(conn, "index.json", accounts: Explorer.list_accounts())
  end

  def show(conn, %{"address" => address}) do
    render(conn, "show.json", account: Explorer.get_account!(address))
  end

end
