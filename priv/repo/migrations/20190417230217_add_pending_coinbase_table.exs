defmodule BlockchainAPI.Repo.Migrations.AddPendingCoinbaseTable do
  use Ecto.Migration
  import Honeydew.EctoPollQueue.Migration
  import BlockchainAPI.Schema.PendingCoinbase, only: [submit_coinbase_queue: 0]

  def up do
    create table(:pending_coinbases) do
      add :amount, :bigint, null: false
      add :payee, :binary, null: false
      add :status, :string, null: false, default: "pending"
      add :hash, :binary, null: false
      add :txn, :binary, null: false

      honeydew_fields(submit_coinbase_queue())

      timestamps()
    end

    create unique_index(:pending_coinbases, [:hash], name: :unique_pending_coinbase)
    honeydew_indexes(:pending_coinbases, submit_coinbase_queue())
  end

  def down do
    drop table(:pending_coinbases)
  end

end
