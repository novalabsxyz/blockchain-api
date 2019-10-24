defmodule BlockchainAPI.Repo.Migrations.AddPendingOUITable do
  use Ecto.Migration
  import Honeydew.EctoPollQueue.Migration
  import BlockchainAPI.Schema.PendingOUI, only: [submit_oui_queue: 0]

  def change do
    create table(:pending_ouis) do
      add :hash, :binary, null: false
      add :owner, :binary, null: false
      add :addresses, {:array, :string}, null: false, default: [] # can have empty addresses
      add :payer, :binary, null: true # can have an empty payer
      add :staking_fee, :bigint, null: false, default: 0
      add :oui, :bigint, null: false, default: 1
      add :fee, :bigint, null: false, default: 0
      add :txn, :binary, null: false
      add :submit_height, :bigint, null: false, default: 0
      add :status, :string, null: false, default: "pending"

      honeydew_fields(submit_oui_queue())

      timestamps()
    end

    honeydew_indexes(:pending_ouis, submit_oui_queue())
  end

end
