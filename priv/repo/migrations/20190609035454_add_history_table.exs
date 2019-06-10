defmodule BlockchainAPI.Repo.Migrations.AddHistoryTable do
  use Ecto.Migration

  def change do
    create table(:history) do
      add :height, :bigint, null: false
      add :name, :string, null: false
      add :score, :float, null: false
      add :alpha, :float, null: false
      add :beta, :float, null: false
      add :delta, :float, null: false

      timestamps()
    end

    create unique_index(:history, [:height, :name], name: :unique_height_name)
  end

end
