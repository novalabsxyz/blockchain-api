defmodule BlockchainAPI.Repo.Migrations.AddPendingPaymentTable do
  use Ecto.Migration

  def change do
    create table(:pending_payments) do
      add :hash, :binary, null: false
      add :status, :string, null: false, default: "pending"
      add :nonce, :bigint, null: false, default: 0
      add :payee, :binary, null: false
      add :fee, :bigint, null: false
      add :amount, :bigint, null: false

      add :payer, references(:accounts, on_delete: :nothing, column: :address, type: :binary), null: false

      timestamps()
    end

    create unique_index(:pending_payments, [:payer, :hash], name: :unique_pending_payment)

  end
end
