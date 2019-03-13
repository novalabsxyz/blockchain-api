defmodule BlockchainAPI.Repo.Migrations.AddHotspotTable do
  use Ecto.Migration

  def change do
    create table(:hotspots, primary_key: false) do
      add :gateway, :binary, null: false, primary_key: true
      add :owner, :binary, null: false
      add :location, :string, null: false
      add :city, :string, null: false
      add :street, :string, null: false
      add :state, :string, null: false
      add :country, :string, null: false

      timestamps()
    end

    create unique_index(:hotspots, [:city, :gateway], name: :unique_city_gateways)
  end
end
