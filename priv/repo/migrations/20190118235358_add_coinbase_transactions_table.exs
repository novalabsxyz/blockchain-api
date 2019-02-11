defmodule BlockchainAPI.Repo.Migrations.AddCoinbaseTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:coinbase_transactions) do
      add :amount, :bigint, null: false
      add :payee, :string, null: false

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :string), null: false
      timestamps()
    end

    create unique_index(:coinbase_transactions, [:hash], name: :unique_coinbase_hash)

  end
end
