defmodule BlockchainAPI.Repo.Migrations.AddConsensusMemberTable do
  use Ecto.Migration

  def up do
    create table(:consensus_members) do
      add :election_transactions_id, references(:election_transactions, on_delete: :nothing, column: :id, type: :bigint), null: false
      add :address, :binary, null: false

      timestamps()
    end
  end

  def down do
    drop table(:consensus_members)
  end

end
