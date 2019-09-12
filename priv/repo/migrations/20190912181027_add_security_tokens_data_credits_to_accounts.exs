defmodule BlockchainAPI.Repo.Migrations.AddSecurityTokensDataCreditsToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :security_balance, :bigint, null: false, default: 0
      add :security_nonce, :bigint, null: false, default: 0
      add :data_credit_balance, :bigint, null: false, default: 0
    end
  end
end
