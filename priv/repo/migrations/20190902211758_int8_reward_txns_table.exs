defmodule BlockchainAPI.Repo.Migrations.Int8RewardTxnsTable do
  use Ecto.Migration

  def change do
    alter table(:reward_txns) do
      modify :amount, :bigint, null: false
    end
  end
end
