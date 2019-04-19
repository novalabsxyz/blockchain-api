defmodule BlockchainAPI.Repo.Migrations.AddPendingCoinbaseTable do
  use Ecto.Migration

  def up do
    create table(:pending_coinbases) do
      add :amount, :bigint, null: false
      add :payee, :binary, null: false
      add :status, :string, null: false, default: "pending"

      add :pending_transactions_hash, references(:pending_transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false

      timestamps()
    end

    create unique_index(:pending_coinbases, [:pending_transactions_hash], name: :unique_pending_coinbase)
  end

  def down do
    drop table(:pending_coinbases)
  end

end
