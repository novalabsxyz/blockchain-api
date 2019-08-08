defmodule BlockchainAPI.Repo.Migrations.ChangeRewardAmountType do
  use Ecto.Migration

  def change do
    alter table(:reward_txns) do
      modify :amount, :bigint, null: false
    end
  end
end
