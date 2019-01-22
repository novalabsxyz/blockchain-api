defmodule BlockchainAPI.Repo.Migrations.AddLocationTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:location_transactions, primary_key: false) do
      add :gateway, :string, null: false
      add :owner, :string, null: false
      add :location, :string, null: false
      add :nonce, :integer, null: false
      add :fee, :integer, null: false

      add :location_hash, references(:transactions, on_delete: :nothing, column: :hash, type: :string), null: false
      timestamps()
    end

    alter table(:location_transactions) do
      modify(:location_hash, :string, primary_key: true)
    end

  end
end
