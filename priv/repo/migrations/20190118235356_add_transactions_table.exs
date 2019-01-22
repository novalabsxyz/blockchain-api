defmodule BlockchainAPI.Repo.Migrations.AddTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :hash, :string, null: false, primary_key: true
      add :type, :string, null: false

      add :block_height, references(:blocks, on_delete: :nothing, column: :height), null: false

      timestamps()
    end

    create unique_index(:transactions, [:hash])

  end
end
