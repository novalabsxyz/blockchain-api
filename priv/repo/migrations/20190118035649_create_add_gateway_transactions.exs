defmodule BlockchainAPI.Repo.Migrations.CreateAddGatewayTransactions do
  use Ecto.Migration

  def change do
    create table(:add_gateway_transactions) do
      add :type, :string, null: false
      add :owner, :string, null: false
      add :gateway, :string, null: false
      add :hash, :string, null: false

      add :block_height, references(:blocks, on_delete: :nothing, column: :height)

      timestamps()
    end

    create index(:add_gateway_transactions, [:block_height])
  end
end
