defmodule BlockchainAPI.Repo.Migrations.AddTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :hash, :string, primary_key: true
      add :type, :string, null: false

      add :block_height, references(:blocks, on_delete: :nothing, column: :height)

      timestamps()
    end

    alter table(:transactions) do
      modify(:block_height, :bigint, null: false)
    end
  end
end
