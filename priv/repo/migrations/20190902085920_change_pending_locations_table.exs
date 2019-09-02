defmodule BlockchainAPI.Repo.Migrations.ChangePendingLocationsTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(index("pending_locations", ["owner"], name: "pending_location_owner"))
  end
end
