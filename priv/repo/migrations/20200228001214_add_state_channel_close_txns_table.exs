defmodule BlockchainAPI.Repo.Migrations.AddStateChannelCloseTxnsTable do
  use Ecto.Migration

  def change do

    create table(:state_channel_close_transactions) do

      add :closer, :binary, null: false
      add :state_channel, :map, null: false
      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :binary), null: false

      timestamps()
    end
  end
end
