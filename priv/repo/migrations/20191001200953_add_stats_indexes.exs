defmodule BlockchainAPI.Repo.Migrations.AddStatsIndexes do
  use Ecto.Migration

  def change do
    create index(:transactions, [:type])
    create index(:consensus_members, [:election_transactions_id])
  end
end
