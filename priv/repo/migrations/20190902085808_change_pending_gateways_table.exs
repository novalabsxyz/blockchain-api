defmodule BlockchainAPI.Repo.Migrations.ChangePendingGatewaysTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(index("pending_gateways", ["owner"], name: "pending_gateway_owner"))
  end
end
