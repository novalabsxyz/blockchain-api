defmodule BlockchainAPI.Repo.Migrations.AddPocPathElementsTable do
  use Ecto.Migration

  def change do
    create table(:poc_path_elements) do
      add :poc_receipts_transactions_hash, references(:poc_receipts_transactions, on_delete: :delete_all, column: :hash, type: :binary), null: false
      add :challengee, :binary, null: true # NOTE: last path element has no challengee by design
      add :challengee_loc, :string, null: true
      add :challengee_owner, :binary, null: false
      add :result, :string, null: false, default: "untested"

      timestamps()
    end

    create index(:poc_path_elements, [:poc_receipts_transactions_hash])
  end

end
