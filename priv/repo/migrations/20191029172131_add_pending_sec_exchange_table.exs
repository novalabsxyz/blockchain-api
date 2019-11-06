defmodule BlockchainAPI.Repo.Migrations.AddPendingSecExchangeTable do
  use Ecto.Migration
  import Honeydew.EctoPollQueue.Migration
  import BlockchainAPI.Schema.PendingSecExchange, only: [submit_sec_exchange_queue: 0]

  def change do
    create table(:pending_sec_exchanges) do
      add :hash, :binary, null: false
      add :amount, :bigint, null: false
      add :payee, :binary, null: false
      add :payer, :binary, null: false
      add :fee, :bigint, null: false, default: 0
      add :nonce, :bigint, null: false, default: 1
      add :signature, :binary, null: false
      add :status, :string, null: false, default: "pending"
      add :txn, :binary, null: false
      add :submit_height, :bigint, null: false, default: 0

      honeydew_fields(submit_sec_exchange_queue())

      timestamps()
    end

    honeydew_indexes(:pending_sec_exchanges, submit_sec_exchange_queue())
  end
end
