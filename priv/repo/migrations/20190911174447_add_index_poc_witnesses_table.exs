defmodule BlockchainAPI.Repo.Migrations.AddIndexPocWitnessesTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(index("poc_witnesses", ["gateway"], name: "poc_witnesses_gateway"))
  end
end
