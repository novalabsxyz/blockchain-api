defmodule BlockchainAPI.Repo.Migrations.ChangePendingPaymentsTable do
  use Ecto.Migration

  def change do
    create_if_not_exists(index("pending_payments", ["payee"], name: "pending_payments_payee"))
    create_if_not_exists(index("pending_payments", ["payer"], name: "pending_payments_payer"))
  end
end
