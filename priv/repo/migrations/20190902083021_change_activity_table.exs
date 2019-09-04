defmodule BlockchainAPI.Repo.Migrations.ChangeActivityTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(index("hotspot_activity", ["gateway"], name: "gateway"))
  end
end
