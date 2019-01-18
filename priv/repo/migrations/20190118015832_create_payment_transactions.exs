defmodule BlockchainAPI.Repo.Migrations.CreatePaymentTransactions do
  use Ecto.Migration

  def change do
    create table(:payment_transactions) do
      add :type, :string, null: false
      add :amount, :bigint, null: false
      add :payee, :string, null: false
      add :payer, :string, null: false
      add :fee, :integer, null: false
      add :nonce, :integer, null: false
      add :block_height, references(:blocks, on_delete: :nothing, column: :height)

      timestamps()
    end

    create index(:payment_transactions, [:block_height])
  end
end
