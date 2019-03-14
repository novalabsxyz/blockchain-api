defmodule BlockchainAPI.Repo.Migrations.AddHotspotTable do
  use Ecto.Migration

  def change do
    create table(:hotspots) do
      add :address, :binary, null: false
      add :owner, :binary, null: false
      add :location, :string, null: false
      add :city, :string, null: false
      add :street, :string, null: false
      add :state, :string, null: false
      add :country, :string, null: false

      timestamps()
    end

    create unique_index(:hotspots, [:address], name: :unique_hotspots)
    create unique_index(:hotspots, [:city, :address], name: :unique_city_hotspots)
  end
end
