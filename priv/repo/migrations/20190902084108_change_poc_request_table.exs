defmodule BlockchainAPI.Repo.Migrations.ChangePocRequestTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(unique_index("poc_request_transactions", ["onion"], name: "unique_onion"))
  end
end
