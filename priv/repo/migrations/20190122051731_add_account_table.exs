defmodule BlockchainAPI.Repo.Migrations.AddAccountTable do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :address, :binary, null: false
      add :name, :string
      add :balance, :bigint, null: false
      add :fee, :bigint, null: false, default: 0
      add :nonce, :bigint, null: false, default: 0

      timestamps()
    end

    create unique_index(:accounts, [:address], name: :unique_account_address)
  end

end
