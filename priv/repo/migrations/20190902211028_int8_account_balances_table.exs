defmodule BlockchainAPI.Repo.Migrations.Int8AccountBalancesTable do
  use Ecto.Migration

  def change do
    alter table(:account_balances) do
      modify :block_time, :bigint, null: false
      modify :block_height, :bigint, null: false
    end
  end
end
