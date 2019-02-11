defmodule BlockchainAPI.Repo.Migrations.AddLocationTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:location_transactions) do
      add :gateway, :string, null: false
      add :owner, :string, null: false
      add :location, :string, null: false
      add :nonce, :integer, null: false
      add :fee, :integer, null: false

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :string), null: false
      timestamps()
    end

    create unique_index(:location_transactions, [:hash], name: :unique_location_hash)

  end
end
