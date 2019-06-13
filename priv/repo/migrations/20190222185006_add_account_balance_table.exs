defmodule BlockchainAPI.Repo.Migrations.AddAccountBalanceTable do
  use Ecto.Migration

  def change do
    create table(:account_balances) do
      add :account_address, :binary, null: false
      add :block_time, :integer, null: false
      add :block_height, :integer, null: false
      add :balance, :bigint, null: false
      add :delta, :bigint, null: false

      timestamps()
    end

    # composite uniqueness for account_address, block_time, balance
    create unique_index(:account_balances, [:account_address, :block_height, :balance], name: :unique_account_height_balance)
  end

end
