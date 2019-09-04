defmodule BlockchainAPI.Repo.Migrations.ChangePocReceiptsTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(unique_index("poc_receipts", ["poc_path_elements_id"], name: "unique_path_receipt"))
  end
end
