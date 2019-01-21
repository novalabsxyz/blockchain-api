defmodule BlockchainAPI.Repo.Migrations.AddCoinbaseTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:coinbase_transactions, primary_key: false) do
      add :amount, :bigint, null: false
      add :payee, :string, null: false

      add :coinbase_hash, references(:transactions, on_delete: :nothing, column: :hash, type: :string), null: false
      timestamps()
    end

    alter table(:coinbase_transactions) do
      modify(:coinbase_hash, :string, primary_key: true)
    end

  end
end
