defmodule BlockchainAPI.Repo.Migrations.AddPaymentTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:payment_transactions) do
      add :amount, :bigint, null: false
      add :payee, :binary, null: false
      add :payer, :binary, null: false
      add :fee, :bigint, null: false
      add :nonce, :bigint, null: false, default: 0
      add :status, :string, null: false, default: "cleared"

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :binary), null: false
      timestamps()
    end

    create unique_index(:payment_transactions, [:hash], name: :unique_payment_hash)

  end
end
