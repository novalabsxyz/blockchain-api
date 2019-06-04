defmodule BlockchainAPI.Repo.Migrations.AddHotspotTable do
  use Ecto.Migration

  def up do
    create table(:hotspots) do
      add :address, :binary, null: false
      add :owner, :binary, null: false
      add :score, :float, null: false, default: 0.0
      add :location, :string, null: true
      add :long_city, :string, null: true
      add :long_street, :string, null: true
      add :long_state, :string, null: true
      add :long_country, :string, null: true
      add :short_street, :string, null: true
      add :short_city, :string, null: true
      add :short_state, :string, null: true
      add :short_country, :string, null: true
      add :score_update_height, :bigint, null: false, default: 0

      timestamps()
    end

    create unique_index(:hotspots, [:address], name: :unique_hotspots)
  end

  def down do
    drop table(:hotspots)
  end

end
