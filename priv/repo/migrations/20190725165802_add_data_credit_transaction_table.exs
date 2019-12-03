defmodule BlockchainAPI.Repo.Migrations.AddDataCreditTransactionTable do
  use Ecto.Migration

  def change do
    create table(:data_credit_transactions) do
      add :amount, :bigint, null: false
      add :payee, :binary, null: false
      add :status, :string, null: false, default: "cleared"

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :binary), null: false
      timestamps()
    end

    create unique_index(:data_credit_transactions, [:hash], name: :unique_data_credit_hash)

  end
end
