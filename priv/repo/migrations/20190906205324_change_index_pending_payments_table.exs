defmodule BlockchainAPI.Repo.Migrations.ChangeIndexPendingPaymentsTable do
  use Ecto.Migration

  def change do
    drop_if_exists(unique_index("pending_payments", ["unique_pending_payment_nonce"], name: "unique_pending_payment_nonce"))
  end
end
