defmodule BlockchainAPI.Repo.Migrations.AddSecurityTransactionTable do
  use Ecto.Migration

  def change do
    create table(:security_transactions) do
      add :amount, :bigint, null: false
      add :payee, :binary, null: false
      add :status, :string, null: false, default: "cleared"

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :binary), null: false
      timestamps()
    end

    create unique_index(:security_transactions, [:hash], name: :unique_security_hash)
  end

end
