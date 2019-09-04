defmodule BlockchainAPI.Repo.Migrations.Int8RewardsTransactionsTable do
  use Ecto.Migration

  def change do
    alter table(:rewards_transactions) do
      modify :fee, :bigint, null: false
    end
  end
end
