defmodule BlockchainAPI.Repo.Migrations.AddBlocksTable do
  use Ecto.Migration

  def change do
    create table(:blocks, primary_key: false) do
      add :height, :bigint, primary_key: true
      add :hash, :string, null: false
      add :round, :integer, null: false
      add :time, :integer, null: false

      timestamps()
    end
  end
end
