defmodule BlockchainAPI.Repo.Migrations.AddRewardTxnsTable do
  use Ecto.Migration

  def change do
    create table(:reward_txns) do
      add :rewards_hash,
          references(:rewards_transactions, on_delete: :nothing, column: :hash, type: :binary),
          null: false

      add :account, :binary, null: false
      # NOTE: security reward has no gateway
      add :gateway, :binary, null: true
      add :amount, :integer, null: false
      add :type, :string, null: false

      timestamps()
    end

    create index(:reward_txns, [:rewards_hash])
  end
end
