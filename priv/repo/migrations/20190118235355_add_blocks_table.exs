defmodule BlockchainAPI.Repo.Migrations.AddBlocksTable do
  use Ecto.Migration

  def change do
    create table(:blocks) do
      add :height, :bigint, null: false
      add :hash, :binary, null: false
      add :round, :integer, null: false
      add :time, :integer, null: false

      timestamps()
    end

    create unique_index(:blocks, [:height], name: :unique_block_height)

  end
end
