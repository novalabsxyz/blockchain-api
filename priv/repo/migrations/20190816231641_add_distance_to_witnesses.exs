defmodule BlockchainAPI.Repo.Migrations.AddDistanceToWitnesses do
  use Ecto.Migration

  def change do
    alter table(:poc_witnesses) do
      add :distance, :float
    end
  end
end
