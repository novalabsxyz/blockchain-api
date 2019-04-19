defmodule BlockchainAPI.Repo.Migrations.AddAccountTransactionTable do
  use Ecto.Migration

  def up do
    create table(:account_transactions) do
      add :account_address, :binary, null: false
      add :txn_hash, :binary, null: false
      add :txn_type, :string, null: false
      add :txn_status, :string, null: false

      timestamps()
    end

    create unique_index(:account_transactions, [:account_address, :txn_hash, :txn_status], name: :unique_account_txn)
  end

  def down do
    drop table(:account_transactions)
  end

end
