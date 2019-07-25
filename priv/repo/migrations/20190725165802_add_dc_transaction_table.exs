defmodule BlockchainAPI.Repo.Migrations.AddDcTransactionTable do
  use Ecto.Migration

  def change do
    create table(:dc_transactions) do
      add :amount, :bigint, null: false
      add :payee, :binary, null: false
      add :status, :string, null: false, default: "cleared"

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :binary), null: false
      timestamps()
    end

    create unique_index(:dc_transactions, [:hash], name: :unique_dc_hash)

  end
end
