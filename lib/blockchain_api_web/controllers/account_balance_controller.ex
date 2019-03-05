defmodule BlockchainAPIWeb.AccountBalanceController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, DBManager, Schema.Account}
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def show(conn, %{"address" => address}) do
    bin_address = address |> Util.string_to_bin()
    account = bin_address |> DBManager.get_account!() |> Account.encode_model()
    account_balance_history = bin_address |> DBManager.get_account_balance_history()
    account_balance = Map.merge(account, %{history: account_balance_history})

    conn
    |> put_view(BlockchainAPIWeb.AccountBalanceView)
    |> render("show.json", account_balance: account_balance)
  end
end
