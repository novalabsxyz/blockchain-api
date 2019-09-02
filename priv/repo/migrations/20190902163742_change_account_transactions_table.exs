defmodule BlockchainAPI.Repo.Migrations.ChangeAccountTransactionsTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(index("account_transactions", ["account_address"], name: "account_txn_address"))
  end
end
