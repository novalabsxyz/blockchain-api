defmodule BlockchainAPI.Repo.Migrations.AddHotspotName do
  use Ecto.Migration

  def change do
    alter table("hotspots") do
      add :name, :string, default: "", null: false
    end
  end
end
