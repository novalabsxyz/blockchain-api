defmodule BlockchainAPI.Repo.Migrations.AddPocRequestTransactionTable do
  use Ecto.Migration

  def change do
    create table(:poc_request_transactions) do
      add :signature, :binary, null: false
      add :fee, :bigint, null: false
      add :onion, :binary, null: false
      add :location, :string, null: false
      add :owner, :binary, null: false

      add :hash, references(:transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
      add :challenger, references(:gateway_transactions, on_delete: :delete_all, column: :gateway, type: :binary), null: false
      timestamps()
    end

    create unique_index(:poc_request_transactions, [:hash], name: :unique_poc_hash)
  end

end
