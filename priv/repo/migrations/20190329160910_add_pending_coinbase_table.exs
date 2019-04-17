defmodule BlockchainAPI.Repo.Migrations.AddPendingCoinbaseTable do
  use Ecto.Migration

  def up do
    create table(:pending_coinbases) do
      add :amount, :bigint, null: false
      add :payee, :binary, null: false
      add :status, :string, null: false, default: "pending"

      add :hash, references(:pending_transactions, on_delete: :nothing, column: :hash, type: :binary), null: false

      timestamps()
    end

    create unique_index(:pending_coinbases, [:hash], name: :unique_pending_coinbase)
  end

  def down do
    drop table(:pending_coinbases)
  end

end
