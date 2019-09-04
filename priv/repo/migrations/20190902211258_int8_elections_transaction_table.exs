defmodule BlockchainAPI.Repo.Migrations.Int8ElectionsTransactionTable do
  use Ecto.Migration

  def change do
    alter table(:election_transactions) do
      modify :delay, :bigint, null: false
    end
  end
end
