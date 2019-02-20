defmodule BlockchainAPI.Repo.Migrations.AddPendingTransationTable do
  use Ecto.Migration

  def change do
    create table(:pending_transactions) do
      add :hash, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :type, :string, null: false
      add :nonce, :bigint, null: false, default: 0

      add :account_address, references(:accounts, on_delete: :nothing, column: :address, type: :string), null: false

      timestamps()
    end

    create unique_index(:pending_transactions, [:account_address, :hash], name: :unique_account_pending_txn)
  end
end
