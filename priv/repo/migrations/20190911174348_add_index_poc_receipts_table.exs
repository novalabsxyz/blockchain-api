defmodule BlockchainAPI.Repo.Migrations.AddIndexPocReceiptsTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(index("poc_receipts", ["gateway"], name: "poc_receipts_gateway"))
  end
end
