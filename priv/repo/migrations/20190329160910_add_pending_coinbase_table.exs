defmodule BlockchainAPI.Repo.Migrations.AddPendingCoinbaseTable do
  use Ecto.Migration

  def change do
    create table(:pending_coinbases) do
      add :amount, :bigint, null: false
      add :payee, :binary, null: false
      add :status, :string, null: false, default: "pending"
      add :hash, :binary, null: false

      timestamps()
    end

    create unique_index(:pending_coinbases, [:hash], name: :unique_pending_coinbase)

  end
end
