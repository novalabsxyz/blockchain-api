defmodule BlockchainAPIWeb.AccountController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Watcher, Util, Query, Schema}
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    accounts = Query.Account.list(params)

    render(conn,
      "index.json",
      accounts: accounts
    )
  end

  def show(conn, %{"address" => address}) do
    try do
      bin_address = address |> Util.string_to_bin()
      account = bin_address |> Query.Account.get!() |> Schema.Account.encode_model()
      account_security_balance =
        case Query.SecurityTransaction.get_balance(bin_address) do
          nil -> 0
          b -> b.amount
        end

      account_dc_balance =
        case Query.DCTransaction.get_balance(bin_address) do
          nil -> 0
          b -> b.amount
        end

      account_balance_history = bin_address |> Query.AccountBalance.get_history()

      account_data = account
                     |> Map.merge(
                       %{history: account_balance_history,
                         nonce: Query.Account.get_speculative_nonce(bin_address),
                         security_balance: account_security_balance,
                         dc_balance: account_dc_balance
                       })

      render(conn, "show.json", account: account_data)
    rescue
      # NOTE: This should probably be somewhere else and feels like a hack
      # This account does not exist in the database, hence we return some default values
      _error in Ecto.NoResultsError ->
        {:ok, fee} = Watcher.chain()
                     |> :blockchain.ledger()
                     |> :blockchain_ledger_v1.transaction_fee()
        non_existent_account =
          %{
            address: address,
            fee: fee,
            balance: 0,
            security_balance: 0,
            dc_balance: 0,
            history: %{
              day: Enum.map(1..24, fn(_) -> 0 end),
              week: Enum.map(1..22, fn(_) -> 0 end),
              month: Enum.map(1..31, fn(_) -> 0 end)
            },
            id: nil,
            name: nil,
            nonce: 0
          }
        render(conn, "show.json", account: non_existent_account)
    end
  end
end
