defmodule BlockchainAPI.Repo.Migrations.AllowDeletion do
  use Ecto.Migration

  def up do
    drop(constraint(:transactions, "transactions_block_height_fkey"))
    alter table(:transactions) do
      modify :block_height, references(:blocks, on_delete: :delete_all, column: :height), null: false
    end

    drop(constraint(:hotspot_activity, "hotspot_activity_gateway_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_req_txn_block_height_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_req_txn_block_time_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_req_txn_hash_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_rx_challenge_id_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_rx_id_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_rx_txn_block_height_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_rx_txn_block_time_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_rx_txn_hash_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_witness_challenge_id_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_witness_id_fkey"))
    alter table(:hotspot_activity) do
      modify :gateway, references(:gateway_transactions, on_delete: :delete_all, column: :gateway, type: :binary), null: false
      modify :poc_req_txn_hash, references(:poc_request_transactions, delete_all: :delete_all, column: :hash, type: :binary), null: true
      modify :poc_req_txn_block_height, references(:blocks, on_delete: :delete_all, column: :height), null: true
      modify :poc_req_txn_block_time, references(:blocks, on_delete: :delete_all, column: :time), null: true
      modify :poc_rx_txn_hash, references(:poc_receipts_transactions, on_delete: :delete_all, column: :hash, type: :binary), null: true
      modify :poc_rx_txn_block_height, references(:blocks, on_delete: :delete_all, column: :height), null: true
      modify :poc_rx_txn_block_time, references(:blocks, on_delete: :delete_all, column: :time), null: true
      modify :poc_witness_id, references(:poc_witnesses, on_delete: :delete_all, column: :id), null: true
      modify :poc_rx_id, references(:poc_receipts, on_delete: :delete_all, column: :id), null: true
      modify :poc_witness_challenge_id, references(:poc_receipts_transactions, on_delete: :delete_all, column: :id), null: true
      modify :poc_rx_challenge_id, references(:poc_receipts_transactions, on_delete: :delete_all, column: :id), null: true
    end

    drop constraint(:poc_path_elements, "poc_path_elements_poc_receipts_transactions_hash_fkey")
    alter table(:poc_path_elements) do
      modify :poc_receipts_transactions_hash, references(:poc_receipts_transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:security_exchange_transactions, "security_exchange_transactions_hash_fkey")
    alter table(:security_exchange_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:poc_receipts, "poc_receipts_poc_path_elements_id_fkey")
    alter table(:poc_receipts) do
      modify :poc_path_elements_id, references(:poc_path_elements, on_delete: :delete_all, column: :id, type: :bigint), null: false
    end

    drop constraint(:poc_witnesses, "poc_witnesses_poc_path_elements_id_fkey")
    alter table(:poc_witnesses) do
      modify :poc_path_elements_id, references(:poc_path_elements, on_delete: :delete_all, column: :id, type: :bigint), null: false
    end

    drop constraint(:security_transactions, "security_transactions_hash_fkey")
    alter table(:security_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:rewards_transactions, "rewards_transactions_hash_fkey")
    alter table(:rewards_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:coinbase_transactions, "coinbase_transactions_hash_fkey")
    alter table(:coinbase_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:reward_txns, "reward_txns_rewards_hash_fkey")
    alter table(:reward_txns) do
      modify :rewards_hash, references(:rewards_transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:payment_transactions, "payment_transactions_hash_fkey")
    alter table(:payment_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:gateway_transactions, "gateway_transactions_hash_fkey")
    alter table(:gateway_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:data_credit_transactions, "data_credit_transactions_hash_fkey")
    alter table(:data_credit_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:poc_request_transactions, "poc_request_transactions_challenger_fkey")
    drop constraint(:poc_request_transactions, "poc_request_transactions_hash_fkey")
    alter table(:poc_request_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
      modify :challenger, references(:gateway_transactions, on_delete: :delete_all, column: :gateway, type: :binary), null: false
    end

    drop constraint(:oui_transactions, "oui_transactions_hash_fkey")
    alter table(:oui_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:pending_locations, "pending_locations_owner_fkey")
    alter table(:pending_locations) do
      modify :owner, references(:accounts, on_delete: :delete_all, column: :address, type: :binary), null: false
    end

    drop constraint(:pending_payments, "pending_payments_payer_fkey")
    alter table(:pending_payments) do
      modify :payer, references(:accounts, on_delete: :delete_all, column: :address, type: :binary), null: false
    end

    drop constraint(:pending_gateways, "pending_gateways_owner_fkey")
    alter table(:pending_gateways) do
      modify :owner, references(:accounts, on_delete: :delete_all, column: :address, type: :binary), null: false
    end

    drop constraint(:consensus_members, "consensus_members_election_transactions_id_fkey")
    alter table(:consensus_members) do
      modify :election_transactions_id, references(:election_transactions, on_delete: :delete_all, column: :id, type: :bigint), null: false
    end

    drop constraint(:location_transactions, "location_transactions_gateway_fkey")
    drop constraint(:location_transactions, "location_transactions_hash_fkey")
    alter table(:location_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
      modify :gateway, references(:gateway_transactions, on_delete: :delete_all, column: :gateway, type: :binary), null: false
    end

    drop constraint(:poc_receipts_transactions, "poc_receipts_transactions_challenger_fkey")
    drop constraint(:poc_receipts_transactions, "poc_receipts_transactions_hash_fkey")
    drop constraint(:poc_receipts_transactions, "poc_receipts_transactions_poc_request_transactions_id_fkey")
    alter table(:poc_receipts_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
      modify :challenger, references(:gateway_transactions, on_delete: :delete_all, column: :gateway, type: :binary), null: false
      modify :poc_request_transactions_id, references(:poc_request_transactions, on_delete: :delete_all, column: :id, type: :bigint), null: false
    end

    drop constraint(:election_transactions, "election_transactions_hash_fkey")
    alter table(:election_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end
  end

  def down do
    drop(constraint(:transactions, "transactions_block_height_fkey"))
    alter table(:transactions) do
      modify :block_height, references(:blocks, on_delete: :delete_all, column: :height), null: false
    end

    drop(constraint(:hotspot_activity, "hotspot_activity_gateway_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_req_txn_block_height_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_req_txn_block_time_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_req_txn_hash_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_rx_challenge_id_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_rx_id_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_rx_txn_block_height_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_rx_txn_block_time_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_rx_txn_hash_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_witness_challenge_id_fkey"))
    drop(constraint(:hotspot_activity, "hotspot_activity_poc_witness_id_fkey"))
    alter table(:hotspot_activity) do
      modify :gateway, references(:gateway_transactions, on_delete: :delete_all, column: :gateway, type: :binary), null: false
      modify :poc_req_txn_hash, references(:poc_request_transactions, delete_all: :delete_all, column: :hash, type: :binary), null: true
      modify :poc_req_txn_block_height, references(:blocks, on_delete: :delete_all, column: :height), null: true
      modify :poc_req_txn_block_time, references(:blocks, on_delete: :delete_all, column: :time), null: true
      modify :poc_rx_txn_hash, references(:poc_receipts_transactions, on_delete: :delete_all, column: :hash, type: :binary), null: true
      modify :poc_rx_txn_block_height, references(:blocks, on_delete: :delete_all, column: :height), null: true
      modify :poc_rx_txn_block_time, references(:blocks, on_delete: :delete_all, column: :time), null: true
      modify :poc_witness_id, references(:poc_witnesses, on_delete: :delete_all, column: :id), null: true
      modify :poc_rx_id, references(:poc_receipts, on_delete: :delete_all, column: :id), null: true
      modify :poc_witness_challenge_id, references(:poc_receipts_transactions, on_delete: :delete_all, column: :id), null: true
      modify :poc_rx_challenge_id, references(:poc_receipts_transactions, on_delete: :delete_all, column: :id), null: true
    end

    drop constraint(:poc_path_elements, "poc_path_elements_poc_receipts_transactions_hash_fkey")
    alter table(:poc_path_elements) do
      modify :poc_receipts_transactions_hash, references(:poc_receipts_transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:security_exchange_transactions, "security_exchange_transactions_hash_fkey")
    alter table(:security_exchange_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:poc_receipts, "poc_receipts_poc_path_elements_id_fkey")
    alter table(:poc_receipts) do
      modify :poc_path_elements_id, references(:poc_path_elements, on_delete: :delete_all, column: :id, type: :bigint), null: false
    end

    drop constraint(:poc_witnesses, "poc_witnesses_poc_path_elements_id_fkey")
    alter table(:poc_witnesses) do
      modify :poc_path_elements_id, references(:poc_path_elements, on_delete: :delete_all, column: :id, type: :bigint), null: false
    end

    drop constraint(:security_transactions, "security_transactions_hash_fkey")
    alter table(:security_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:rewards_transactions, "rewards_transactions_hash_fkey")
    alter table(:rewards_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:coinbase_transactions, "coinbase_transactions_hash_fkey")
    alter table(:coinbase_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:reward_txns, "reward_txns_rewards_hash_fkey")
    alter table(:reward_txns) do
      modify :rewards_hash, references(:rewards_transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:payment_transactions, "payment_transactions_hash_fkey")
    alter table(:payment_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:gateway_transactions, "gateway_transactions_hash_fkey")
    alter table(:gateway_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:data_credit_transactions, "data_credit_transactions_hash_fkey")
    alter table(:data_credit_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:poc_request_transactions, "poc_request_transactions_challenger_fkey")
    drop constraint(:poc_request_transactions, "poc_request_transactions_hash_fkey")
    alter table(:poc_request_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
      modify :challenger, references(:gateway_transactions, on_delete: :delete_all, column: :gateway, type: :binary), null: false
    end

    drop constraint(:oui_transactions, "oui_transactions_hash_fkey")
    alter table(:oui_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end

    drop constraint(:pending_locations, "pending_locations_owner_fkey")
    alter table(:pending_locations) do
      modify :owner, references(:accounts, on_delete: :delete_all, column: :address, type: :binary), null: false
    end

    drop constraint(:pending_payments, "pending_payments_payer_fkey")
    alter table(:pending_payments) do
      modify :payer, references(:accounts, on_delete: :delete_all, column: :address, type: :binary), null: false
    end

    drop constraint(:pending_gateways, "pending_gateways_owner_fkey")
    alter table(:pending_gateways) do
      modify :owner, references(:accounts, on_delete: :delete_all, column: :address, type: :binary), null: false
    end

    drop constraint(:consensus_members, "consensus_members_election_transactions_id_fkey")
    alter table(:consensus_members) do
      modify :election_transactions_id, references(:election_transactions, on_delete: :delete_all, column: :id, type: :bigint), null: false
    end

    drop constraint(:location_transactions, "location_transactions_gateway_fkey")
    drop constraint(:location_transactions, "location_transactions_hash_fkey")
    alter table(:location_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
      modify :gateway, references(:gateway_transactions, on_delete: :delete_all, column: :gateway, type: :binary), null: false
    end

    drop constraint(:poc_receipts_transactions, "poc_receipts_transactions_challenger_fkey")
    drop constraint(:poc_receipts_transactions, "poc_receipts_transactions_hash_fkey")
    drop constraint(:poc_receipts_transactions, "poc_receipts_transactions_poc_request_transactions_id_fkey")
    alter table(:poc_receipts_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
      modify :challenger, references(:gateway_transactions, on_delete: :delete_all, column: :gateway, type: :binary), null: false
      modify :poc_request_transactions_id, references(:poc_request_transactions, on_delete: :delete_all, column: :id, type: :bigint), null: false
    end

    drop constraint(:election_transactions, "election_transactions_hash_fkey")
    alter table(:election_transactions) do
      modify :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
    end
  end

end
