defmodule BlockchainAPI.Repo.Migrations.AddPendingPaymentTable do
  use Ecto.Migration

  def up do
    create table(:pending_payments) do
      add :status, :string, null: false, default: "pending"
      add :nonce, :bigint, null: false, default: 0
      add :payee, :binary, null: false
      add :fee, :bigint, null: false, default: 0
      add :amount, :bigint, null: false

      add :payer, references(:accounts, on_delete: :nothing, column: :address, type: :binary), null: false
      add :pending_transactions_hash, references(:pending_transactions, on_delete: :nothing, column: :hash, type: :binary), null: false

      timestamps()
    end

    create unique_index(:pending_payments, [:payer, :hash, :status], name: :unique_pending_payment)
  end

  def down do
    drop table(:pending_payments)
  end

end
