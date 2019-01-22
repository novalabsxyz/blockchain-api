defmodule BlockchainAPI.Repo.Migrations.AddAccountTable do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :address, :string, primary_key: true
      add :name, :string
      add :balance, :bigint, null: false

      timestamps()
    end
  end
end
