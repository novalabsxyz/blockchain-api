defmodule BlockchainAPI.Repo.Migrations.AddSecurityExchangeTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:security_exchange_transactions) do
      add :amount, :bigint, null: false
      add :payee, :binary, null: false
      add :payer, :binary, null: false
      add :fee, :bigint, null: false
      add :nonce, :bigint, null: false
      add :signature, :binary, null: false
      add :status, :string, null: false, default: "cleared"

      add :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
      timestamps()
    end

    create unique_index(:security_exchange_transactions, [:hash], name: :unique_security_exchange_hash)
  end
end
