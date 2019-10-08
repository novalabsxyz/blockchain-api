defmodule BlockchainAPI.Repo.Migrations.AddActivitiyIndices do
  use Ecto.Migration

  def change do
    create_if_not_exists(index("hotspot_activity", ["poc_req_txn_block_height"], name: "poc_req_txn_block_height"))
    create_if_not_exists(index("hotspot_activity", ["poc_req_txn_block_time"], name: "poc_req_txn_block_time"))
    create_if_not_exists(index("hotspot_activity", ["poc_rx_txn_block_height"], name: "poc_rx_txn_block_height"))
    create_if_not_exists(index("hotspot_activity", ["poc_rx_txn_block_time"], name: "poc_rx_txn_block_time"))
  end
end
