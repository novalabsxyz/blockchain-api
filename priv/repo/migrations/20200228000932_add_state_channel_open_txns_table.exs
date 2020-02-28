defmodule BlockchainAPI.Repo.Migrations.AddStateChannelOpenTxnsTable do
  use Ecto.Migration

  def change do

    create table(:state_channel_open_transactions, primary_key: false) do

      add :id, :binary, null: false, primary_key: true
      add :owner, :binary, null: false
      add :amount, :bigint, null: false
      add :expire_within, :bigint, null: false
      add :nonce, :bigint, null: false

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :binary), null: false

      timestamps()

    end

  end
end
