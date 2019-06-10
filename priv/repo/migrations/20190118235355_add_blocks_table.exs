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
    # NOTE: uncertain to add this, but presumably block times are ALWAYS unique
    # This helps in the creating the composite index for account_balances table
    create unique_index(:blocks, [:time], name: :unique_block_time)
  end

end
