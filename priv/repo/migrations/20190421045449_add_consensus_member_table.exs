defmodule BlockchainAPI.Repo.Migrations.AddConsensusMemberTable do
  use Ecto.Migration

  def change do
    create table(:consensus_members) do
      add :election_transactions_id, references(:election_transactions, on_delete: :delete_all, column: :id, type: :bigint), null: false
      add :address, :binary, null: false

      timestamps()
    end
  end

end
