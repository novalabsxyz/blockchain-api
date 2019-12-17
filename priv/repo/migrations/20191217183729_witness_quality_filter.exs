defmodule BlockchainAPI.Repo.Migrations.WitnessQualityFilter do
  use Ecto.Migration

  def change do
    alter table(:poc_witnesses) do
      add :is_good, :boolean, null: true, default: true
    end
  end
end
