defmodule BlockchainAPI.Repo.Migrations.ChangeBlocksTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(unique_index("blocks", ["hash"], name: "unique_block_hash"))
  end
end
