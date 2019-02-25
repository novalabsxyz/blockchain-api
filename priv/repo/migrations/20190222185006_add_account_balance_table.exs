defmodule BlockchainAPI.Repo.Migrations.AddAccountBalanceTable do
  use Ecto.Migration

  def change do
    create table(:account_balances) do
      add :account_address, references(:accounts, on_delete: :nothing, column: :address, type: :binary), null: false
      add :block_time, references(:blocks, on_delete: :nothing, column: :time, type: :integer), null: false
      add :block_height, references(:blocks, on_delete: :nothing, column: :height, type: :integer), null: false
      add :balance, :bigint, null: false

      timestamps()
    end

    # composite uniqueness for account_address, block_time, balance
    create unique_index(:account_balances, [:account_address, :block_time, :balance], name: :unique_account_time_balance)
  end
end
