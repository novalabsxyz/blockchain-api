defmodule BlockchainAPI.Repo.Migrations.AddPendingGatewayTable do
  use Ecto.Migration
  import Honeydew.EctoPollQueue.Migration
  import BlockchainAPI.Schema.PendingGateway, only: [submit_gateway_queue: 0]

  def change do
    create table(:pending_gateways) do
      add :status, :string, null: false, default: "pending"
      add :gateway, :binary, null: false
      add :fee, :bigint, null: false, default: 0
      add :staking_fee, :bigint, null: false, default: 1
      add :hash, :binary, null: false
      add :txn, :binary, null: false
      add :submit_height, :bigint, null: false, default: 0

      add :owner, references(:accounts, on_delete: :nothing, column: :address, type: :binary), null: false

      honeydew_fields(submit_gateway_queue())

      timestamps()
    end

    create unique_index(:pending_gateways, [:owner, :gateway], name: :unique_pending_gateway_owner)
    create unique_index(:pending_gateways, [:owner, :gateway, :hash, :status, :submit_height], name: :unique_pending_gateway)
    honeydew_indexes(:pending_gateways, submit_gateway_queue())
  end

end
