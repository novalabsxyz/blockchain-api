defmodule BlockchainAPI.Repo.Migrations.AddGatewayTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:gateway_transactions) do
      add :owner, :binary, null: false
      add :gateway, :binary, null: false
      add :fee, :bigint, null: false, default: 0
      add :staking_fee, :bigint, null: false, default: 0
      add :status, :string, null: false, default: "cleared"

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :binary), null: false
      timestamps()
    end

    create unique_index(:gateway_transactions, [:hash], name: :unique_gateway_hash)
    create unique_index(:gateway_transactions, [:gateway], name: :unique_gateway)
  end

end
