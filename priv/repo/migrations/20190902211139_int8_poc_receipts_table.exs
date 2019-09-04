defmodule BlockchainAPI.Repo.Migrations.Int8PocReceiptsTable do
  use Ecto.Migration

  def change do
    alter table(:poc_receipts) do
      modify :signal, :bigint, null: false
    end
  end
end
