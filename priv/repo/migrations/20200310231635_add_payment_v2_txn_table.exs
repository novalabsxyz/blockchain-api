defmodule BlockchainAPI.Repo.Migrations.AddPaymentV2TxnTable do
  use Ecto.Migration

  def change do
    create table(:payment_v2_txns) do
      add :payer, :binary, null: false
      add :payments, :map, null: false
      add :fee, :bigint, null: false
      add :nonce, :bigint, null: false, default: 0
      add :status, :string, null: false, default: "cleared"

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :binary), null: false
      timestamps()
    end

    create unique_index(:payment_v2_txns, [:hash], name: :unique_payment_v2_hash)
  end
end
