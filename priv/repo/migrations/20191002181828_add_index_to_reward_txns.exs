defmodule BlockchainAPI.Repo.Migrations.AddIndexToRewardTxns do
  use Ecto.Migration

  def change do
    create_if_not_exists(index("reward_txns", ["gateway"], name: "reward_txns_gateway"))
  end
end
