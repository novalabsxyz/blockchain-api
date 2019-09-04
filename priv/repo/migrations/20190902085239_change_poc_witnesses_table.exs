defmodule BlockchainAPI.Repo.Migrations.ChangePocWitnessesTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(index("poc_witnesses", ["poc_path_elements_id"], name: "path_witness"))
  end
end
