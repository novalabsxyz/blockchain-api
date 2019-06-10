defmodule BlockchainAPI.Repo.Migrations.AddLocationTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:location_transactions) do
      add :owner, :binary, null: false
      add :location, :binary, null: false
      add :nonce, :bigint, null: false, default: 0
      add :fee, :bigint, null: false, default: 0
      add :status, :string, null: false, default: "cleared"

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :binary), null: false
      add :gateway, references(:gateway_transactions, on_delete: :nothing, column: :gateway, type: :binary), null: false
      timestamps()
    end

    create unique_index(:location_transactions, [:hash], name: :unique_location_hash)
  end

end
