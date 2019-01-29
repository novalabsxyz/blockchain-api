defmodule BlockchainAPIWeb.AccountTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  require Logger
  @default_params %{page: 1, page_size: 10}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"account_address" => address}) do
    render(conn, "index.json", account_transactions: Explorer.get_account_transactions(address, @default_params))
  end
  def index(conn, %{"account_address" => address, "page" => page, "page_size" => page_size}) do
    render(conn,
      "index.json",
      account_transactions: Explorer.get_account_transactions(address,
        %{page: String.to_integer(page), page_size: String.to_integer(page_size)}
      )
    )
  end

end
