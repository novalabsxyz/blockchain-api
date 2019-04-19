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
  end

  def down do
    drop table(:account_transactions)
  end

end
