defmodule BlockchainAPI.Repo.Migrations.AddPendingOuiTable do
  use Ecto.Migration
  import Honeydew.EctoPollQueue.Migration
  import BlockchainAPI.Schema.PendingOui, only: [submit_oui_queue: 0]

  def change do
    create table(:pending_ouis) do
      add :hash, :binary, null: false
      add :owner, :bigint, null: false
      add :addresses, {:array, :binary}, null: false, default: []
      add :payer, :binary, null: false
      add :staking_fee, :bigint, null: false, default: 0
      add :fee, :bigint, null: false, default: 0
      add :txn, :binary, null: false
      add :submit_height, :bigint, null: false, default: 0

      honeydew_fields(submit_oui_queue())

      timestamps()
    end

    honeydew_indexes(:pending_ouis, submit_oui_queue())
  end

end
