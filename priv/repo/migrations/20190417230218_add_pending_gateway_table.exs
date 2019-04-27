defmodule BlockchainAPI.Repo.Migrations.AddPendingGatewayTable do
  use Ecto.Migration
  import Honeydew.EctoPollQueue.Migration
  import BlockchainAPI.Schema.PendingGateway, only: [submit_gateway_queue: 0]

  def up do
    create table(:pending_gateways) do
      add :status, :string, null: false, default: "pending"
      add :gateway, :binary, null: false
      add :fee, :bigint, null: false, default: 0
      add :amount, :bigint, null: false, default: 0
      add :hash, :binary, null: false
      add :txn, :binary, null: false

      add :owner, references(:accounts, on_delete: :nothing, column: :address, type: :binary), null: false

      honeydew_fields(submit_gateway_queue())

      timestamps()
    end

    create unique_index(:pending_gateways, [:owner, :hash, :status], name: :unique_pending_gateway)
    honeydew_indexes(:pending_gateways, submit_gateway_queue())
  end

  def down do
    drop table(:pending_gateways)
  end

end
