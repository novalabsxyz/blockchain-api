defmodule BlockchainAPI.Repo.Migrations.AddOuiTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:oui_transactions) do
      add :owner, :binary, null: false
      add :payer, :binary, null: true # can be empty payer
      add :addresses, {:array, :binary}, null: false, default: [] # can have empty addresses
      add :fee, :bigint, null: false, default: 0
      add :staking_fee, :bigint, null: false, default: 0
      add :oui, :bigint, null: false, default: 1
      add :status, :string, null: false, default: "cleared"

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :binary), null: false
      timestamps()
    end

    create unique_index(:oui_transactions, [:hash], name: :unique_oui_hash)
  end

end
