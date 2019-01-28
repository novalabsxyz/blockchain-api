defmodule BlockchainAPI.Repo.Migrations.AddGatewayTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:gateway_transactions) do
      add :owner, :string, null: false
      add :gateway, :string, null: false

      add :gateway_hash, references(:transactions, on_delete: :nothing, column: :hash, type: :string), null: false
      timestamps()
    end

    create unique_index(:gateway_transactions, [:gateway_hash], name: :unique_gateway_hash)

  end
end
