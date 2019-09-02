defmodule BlockchainAPI.Repo.Migrations.ChangePocReceiptsTransactionsTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(unique_index("poc_receipts_transactions", ["poc_request_transactions_id"], name: "unique_poc_request"))
  end
end
