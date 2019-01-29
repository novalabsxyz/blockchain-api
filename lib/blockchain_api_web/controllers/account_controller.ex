defmodule BlockchainAPIWeb.AccountController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  require Logger

  @default_params %{page: 1, page_size: 10}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) when map_size(params) == 0 do
    render(conn, "index.json", accounts: Explorer.list_accounts(@default_params))
  end
  def index(conn, params) do
    render(conn, "index.json", accounts: Explorer.list_accounts(params))
  end

  def show(conn, %{"address" => address}) do
    render(conn, "show.json", account: Explorer.get_account!(address))
  end

end
