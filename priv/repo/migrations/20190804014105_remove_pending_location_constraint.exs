defmodule BlockchainAPI.Repo.Migrations.RemovePendingLocationConstraint do
  use Ecto.Migration

  def change do
    drop_if_exists(index("pending_locations", ["unique_pending_owner_gateway_nonce"], name: "unique_pending_owner_gateway_nonce"))
  end

end
