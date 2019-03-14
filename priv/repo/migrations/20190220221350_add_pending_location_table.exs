defmodule BlockchainAPI.Repo.Migrations.AddPendingLocationTable do
  use Ecto.Migration

  def change do
    create table(:pending_locations) do
      add :hash, :binary, null: false
      add :status, :string, null: false, default: "pending"
      add :location, :string, null: false
      add :fee, :bigint, null: false, default: 0
      add :nonce, :bigint, null: false
      add :gateway, :binary, null: false

      add :owner, references(:accounts, on_delete: :nothing, column: :address, type: :binary), null: false

      timestamps()
    end

    create unique_index(:pending_locations, [:owner, :gateway, :hash, :status], name: :unique_pending_location)

  end
end
