defmodule BlockchainAPI.Repo.Migrations.AddGatewayTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:gateway_transactions) do
      add :owner, :string, null: false
      add :gateway, :string, null: false
      add :fee, :bigint, null: false, default: 0
      add :amount, :bigint, null: false, default: 0

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :string), null: false
      timestamps()
    end

    create unique_index(:gateway_transactions, [:hash], name: :unique_gateway_hash)
    create unique_index(:gateway_transactions, [:gateway], name: :unique_gateway)

  end
end
