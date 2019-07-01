defmodule BlockchainAPI.Repo.Migrations.AddElectionTransactionTable do
  use Ecto.Migration

  def change do
    create table(:election_transactions) do
      add :proof, :binary, null: true
      add :delay, :integer, null: false
      add :election_height, :bigint, null: false

      add :hash, :binary, null: false
      # add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :binary), null: false
      timestamps()
    end

    create unique_index(:election_transactions, [:hash], name: :unique_election_hash)
  end

end
