defmodule BlockchainAPI.Repo.Migrations.AddTransactionsTable do
  use Ecto.Migration

  def up do
    create table(:transactions) do
      add :hash, :binary, null: false
      add :type, :string, null: false
      add :status, :string, null: false, default: "cleared"

      add :block_height, references(:blocks, on_delete: :nothing, column: :height), null: false

      timestamps()
    end

    create unique_index(:transactions, [:hash], name: :unique_txn_hash)

  end

  def down do
    drop table(:transactions)
  end

end
