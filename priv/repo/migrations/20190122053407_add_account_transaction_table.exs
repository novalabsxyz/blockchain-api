defmodule BlockchainAPI.Repo.Migrations.AddAccountTransactionTable do
  use Ecto.Migration

  def change do
    create table(:account_transactions) do
      add :account_address, references(:accounts, on_delete: :nothing, column: :address, type: :string), null: false
      add :txn_hash, references(:transactions, on_delete: :nothing, column: :hash, type: :string), null: false

      timestamps()
    end

    create unique_index(:account_transactions, [:account_address, :txn_hash], name: :unique_account_txn_hash)
  end
end
