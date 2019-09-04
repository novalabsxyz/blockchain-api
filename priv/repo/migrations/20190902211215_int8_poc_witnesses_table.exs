defmodule BlockchainAPI.Repo.Migrations.Int8PocWitnessesTable do
  use Ecto.Migration

  def change do
    alter table(:poc_witnesses) do
      modify :signal, :bigint, null: false
    end
  end
end
