defmodule BlockchainAPIWeb.AccountController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Watcher, Util, DBManager, Schema.Account}
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
    try do
      bin_address = address |> Util.string_to_bin()
      account = bin_address |> DBManager.get_account!() |> Account.encode_model()
      account_balance_history = bin_address |> DBManager.get_account_balance_history()

      account_data = account
                     |> Map.merge(
                       %{history: account_balance_history,
                         speculative_nonce: DBManager.get_payer_speculative_nonce(bin_address)
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
            history: %{
              day: [],
              week: [],
              month: []
            },
            id: nil,
            name: nil,
            nonce: 0,
            speculative_nonce: 0
          }
        render(conn, "show.json", account: non_existent_account)
    end
  end
end
