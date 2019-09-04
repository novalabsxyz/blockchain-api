defmodule BlockchainAPI.Repo.Migrations.Int8BlocksTable do
  use Ecto.Migration

  def change do
    alter table(:blocks) do
      modify :round, :bigint, null: false
      modify :time, :bigint, null: false
    end
  end
end
