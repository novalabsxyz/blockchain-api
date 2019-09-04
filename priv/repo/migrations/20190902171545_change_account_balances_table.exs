defmodule BlockchainAPI.Repo.Migrations.ChangeAccountBalancesTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(index("account_balances", ["account_address"], name: "account_balance_address"))
  end
end
