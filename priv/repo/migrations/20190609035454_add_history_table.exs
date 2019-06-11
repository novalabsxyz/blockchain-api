defmodule BlockchainAPI.Repo.Migrations.AddHistoryTable do
  use Ecto.Migration

  def change do
    create table(:history) do
      add :name, :string, null: false
      add :score, :float, null: false
      add :alpha, :float, null: false
      add :beta, :float, null: false
      add :delta, :float, null: false

      add :height, references(:blocks, on_delete: :nothing, column: :height), null: false

      timestamps()
    end

    create unique_index(:history, [:height, :name], name: :unique_height_name)
  end

end
