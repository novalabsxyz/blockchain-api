defmodule BlockchainAPI.Repo.Migrations.AddGatewayTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:gateway_transactions, primary_key: false) do
      add :owner, :string, null: false
      add :gateway, :string, null: false

      add :gateway_hash, references(:transactions, on_delete: :nothing, column: :hash, type: :string), null: false
      timestamps()
    end

    alter table(:gateway_transactions) do
      modify(:gateway_hash, :string, primary_key: true)
    end
  end
end
