defmodule BlockchainAPI.Repo.Migrations.Int8HotspotActivityTable do
  use Ecto.Migration

  def change do
    alter table(:hotspot_activity) do
      modify :election_id, :bigint, null: true
      modify :election_txn_block_time, :bigint, null: true
      modify :reward_block_time, :bigint, null: true
    end
  end
end
