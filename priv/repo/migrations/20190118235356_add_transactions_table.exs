defmodule BlockchainAPI.Repo.Migrations.AddTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :hash, :string, null: false
      add :type, :string, null: false

      add :block_height, references(:blocks, on_delete: :nothing, column: :height), null: false

      timestamps()
    end

    create unique_index(:transactions, [:hash], name: :unique_txn_hash)

  end
end
