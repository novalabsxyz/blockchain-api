defmodule BlockchainAPI.Repo.Migrations.AddRewardsTable do
  use Ecto.Migration

  def change do
    create table(:rewards) do
      add :type, :string, null: false
      add :account_address, :binary, null: true
      add :gateway_address, :binary, null: true
      add :amount, :bigint, null: false

      add :block_height, references(:blocks, on_delete: :nothing, column: :height), null: false

      timestamps()
    end
  end
end
