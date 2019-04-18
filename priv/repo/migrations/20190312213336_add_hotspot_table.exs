defmodule BlockchainAPI.Repo.Migrations.AddHotspotTable do
  use Ecto.Migration

  def up do
    create table(:hotspots) do
      add :address, :binary, null: false
      add :owner, :binary, null: false
      add :location, :string, null: false
      add :long_city, :string, null: false
      add :long_street, :string, null: false
      add :long_state, :string, null: false
      add :long_country, :string, null: false
      add :short_street, :string, null: false
      add :short_city, :string, null: false
      add :short_state, :string, null: false
      add :short_country, :string, null: false

      timestamps()
    end

    create unique_index(:hotspots, [:address], name: :unique_hotspots)
    create unique_index(:hotspots, [:short_city, :address], name: :unique_city_hotspots)
  end

  def down do
    drop table(:hotspots)
  end

end
