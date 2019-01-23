defmodule BlockchainAPI.Repo.Migrations.AddAccountTransactionTable do
  use Ecto.Migration

  def change do
    create table(:account_transactions, primary_key: false) do
      add :account_address, references(:accounts, on_delete: :nothing, column: :address, type: :string), null: false
      add :txn_hash, references(:transactions, on_delete: :nothing, column: :hash, type: :string), null: false

      timestamps()
    end

    alter table(:account_transactions, primary_key: false) do
      modify :account_address, :string, primary_key: true
      modify :txn_hash, :string,  primary_key: true
    end

  end
end
