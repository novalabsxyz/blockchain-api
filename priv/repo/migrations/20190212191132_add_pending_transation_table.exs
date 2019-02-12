defmodule BlockchainAPI.Repo.Migrations.AddPendingTransationTable do
  use Ecto.Migration

  def change do
    create table(:pending_transactions) do
      add :hash, :string, null: false
      add :status, :string, null: false, default: "pending"

      timestamps()
    end

    create unique_index(:pending_transactions, [:hash], name: :unique_pending_txn)
  end
end
