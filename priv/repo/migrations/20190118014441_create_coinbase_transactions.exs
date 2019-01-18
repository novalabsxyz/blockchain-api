defmodule BlockchainAPI.Repo.Migrations.CreateCoinbaseTransactions do
  use Ecto.Migration

  def change do
    create table(:coinbase_transactions) do
      add :type, :string, null: false
      add :amount, :bigint, null: false
      add :payee, :string, null: false
      add :block_height, references(:blocks, on_delete: :nothing, column: :height)

      timestamps()
    end

    create index(:coinbase_transactions, [:block_height])
  end
end
