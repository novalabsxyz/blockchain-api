defmodule BlockchainAPI.Repo.Migrations.AddRewardsTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:rewards_transactions) do
      add :fee, :integer, null: false

      add :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
      timestamps()
    end

    create unique_index(:rewards_transactions, [:hash], name: :unique_rewards_hash)
  end
end
