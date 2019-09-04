defmodule BlockchainAPI.Repo.Migrations.ChangeTransactionsTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(index("transactions", ["block_height"], name: "block_height"))
  end
end
