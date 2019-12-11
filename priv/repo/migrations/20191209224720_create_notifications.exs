defmodule BlockchainAPI.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :style, :string, null: false, default: "default"
      add :icon, :string, null: true
      add :color, :string, null: true
      add :title, :json, null: false
      add :body, :json, null: false
      add :share_text, :json, null: true
      add :account_address, :string, null: false
      add :hotspot_address, :string, null: true
      add :hotspot_name, :string, null: true
      add :viewed_at, :utc_datetime, null: true

      timestamps()
    end

    create index(:notifications, [:account_address, :viewed_at])
  end
end
