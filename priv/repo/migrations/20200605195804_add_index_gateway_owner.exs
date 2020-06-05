defmodule BlockchainAPI.Repo.Migrations.AddIndexGatewayOwner do
  use Ecto.Migration

  def change do
    create_if_not_exists(index("gateway_transactions", ["owner"], name: "gateway_owner"))
  end
end
