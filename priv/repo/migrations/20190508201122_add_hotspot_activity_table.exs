defmodule BlockchainAPI.Repo.Migrations.AddHotspotActivityTable do
  use Ecto.Migration

  def up do
    create table(:hotspot_activity) do
      add :gateway, references(:gateway_transactions, on_delete: :nothing, column: :gateway, type: :binary), null: false
      add :poc_req_txn_hash, references(:poc_request_transactions, on_delete: :nothing, column: :hash, type: :binary), null: true
      add :poc_req_txn_block_height, references(:blocks, on_delete: :nothing, column: :height), null: true
      add :poc_rx_txn_hash, references(:poc_receipts_transactions, on_delete: :nothing, column: :hash, type: :binary), null: true
      add :poc_rx_txn_block_height, references(:blocks, on_delete: :nothing, column: :height), null: true
      add :poc_witness_id, references(:poc_witnesses, on_delete: :nothing, column: :id), null: true
      add :poc_rx_id, references(:poc_receipts, on_delete: :nothing, column: :id), null: true
      add :poc_witness_challenge_id, references(:poc_receipts_transactions, on_delete: :nothing, column: :id), null: true
      add :poc_rx_challenge_id, references(:poc_receipts_transactions, on_delete: :nothing, column: :id), null: true
      add :poc_score, :float, null: true

      timestamps()
    end
  end

  def down do
    drop table(:hotspot_activity)
  end
end
