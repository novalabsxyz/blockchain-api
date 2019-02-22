defmodule BlockchainAPI.Repo.Migrations.AddLocationTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:location_transactions) do
      add :owner, :string, null: false
      add :location, :string, null: false
      add :nonce, :bigint, null: false, default: 0
      add :fee, :bigint, null: false

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :string), null: false
      add :gateway, references(:gateway_transactions, on_delete: :nothing, column: :gateway, type: :string), null: false
      timestamps()
    end

    create unique_index(:location_transactions, [:hash], name: :unique_location_hash)

  end
end
