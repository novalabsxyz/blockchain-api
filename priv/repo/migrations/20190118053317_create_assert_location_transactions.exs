defmodule BlockchainAPI.Repo.Migrations.CreateAssertLocationTransactions do
  use Ecto.Migration

  def change do
    create table(:assert_location_transactions) do
      add :type, :string, null: false
      add :gateway, :string, null: false
      add :owner, :string, null: false
      add :location, :string, null: false
      add :nonce, :integer, null: false
      add :fee, :integer, null: false
      add :hash, :string, null: false

      add :block_height, references(:blocks, on_delete: :nothing, column: :height)

      timestamps()
    end

    create index(:assert_location_transactions, [:block_height])
  end
end
