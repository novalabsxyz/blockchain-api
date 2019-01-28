defmodule BlockchainAPI.Repo.Migrations.AddPaymentTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:payment_transactions) do
      add :amount, :bigint, null: false
      add :payee, :string, null: false
      add :payer, :string, null: false
      add :fee, :integer, null: false
      add :nonce, :integer, null: false

      add :payment_hash, references(:transactions, on_delete: :nothing, column: :hash, type: :string), null: false
      timestamps()
    end

    create unique_index(:payment_transactions, [:payment_hash], name: :unique_payment_hash)

  end
end
