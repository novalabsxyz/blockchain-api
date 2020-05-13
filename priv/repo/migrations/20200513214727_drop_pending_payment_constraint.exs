defmodule BlockchainAPI.Repo.Migrations.DropPendingPaymentConstraint do
  use Ecto.Migration

  def change do
    drop_if_exists(unique_index("pending_payments", ["unique_pending_payment"], name: "unique_pending_payment"))
  end
end
