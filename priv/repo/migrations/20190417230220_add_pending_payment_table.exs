defmodule BlockchainAPI.Repo.Migrations.AddPendingPaymentTable do
  use Ecto.Migration
  import Honeydew.EctoPollQueue.Migration
  import BlockchainAPI.Schema.PendingPayment, only: [submit_payment_queue: 0]

  def up do
    create table(:pending_payments) do
      add :status, :string, null: false, default: "pending"
      add :nonce, :bigint, null: false, default: 0
      add :payee, :binary, null: false
      add :fee, :bigint, null: false, default: 0
      add :amount, :bigint, null: false
      add :hash, :binary, null: false
      add :txn, :binary, null: false

      add :payer, references(:accounts, on_delete: :nothing, column: :address, type: :binary), null: false

      honeydew_fields(submit_payment_queue())

      timestamps()
    end

    create unique_index(:pending_payments, [:payer, :hash, :status], name: :unique_pending_payment)
    honeydew_indexes(:pending_payments, submit_payment_queue())
  end

  def down do
    drop table(:pending_payments)
  end

end
