defmodule BlockchainAPI.Repo.Migrations.AddPendingLocationTable do
  use Ecto.Migration
  import Honeydew.EctoPollQueue.Migration
  import BlockchainAPI.Schema.PendingLocation, only: [submit_location_queue: 0]

  def change do
    create table(:pending_locations) do
      add :status, :string, null: false, default: "pending"
      add :location, :binary, null: false
      add :fee, :bigint, null: false, default: 0
      add :staking_fee, :bigint, null: false, default: 1
      add :nonce, :bigint, null: false
      add :gateway, :binary, null: false
      add :hash, :binary, null: false
      add :txn, :binary, null: false
      add :submit_height, :bigint, null: false, default: 0

      add :owner, references(:accounts, on_delete: :nothing, column: :address, type: :binary),
        null: false

      honeydew_fields(submit_location_queue())

      timestamps()
    end

    create unique_index(:pending_locations, [:owner, :gateway, :nonce],
             name: :unique_pending_owner_gateway_nonce
           )

    create unique_index(:pending_locations, [:owner, :gateway, :submit_height, :hash, :status],
             name: :unique_pending_location
           )

    honeydew_indexes(:pending_locations, submit_location_queue())
  end
end
