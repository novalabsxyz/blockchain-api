defmodule BlockchainAPI.Repo.Migrations.AddPocReceiptTable do
  use Ecto.Migration

  def change do
    create table(:poc_receipts) do
      add :poc_path_elements_id, references(:poc_path_elements, on_delete: :nothing, column: :id, type: :bigint), null: false
      add :gateway, :binary, null: false
      add :timestamp, :bigint, null: false
      add :signal, :integer, null: false
      add :data, :binary, null: false
      add :signature, :binary, null: false
      add :origin, :string, null: false
      add :location, :string, null: false
      add :primary, :boolean, null: false

      timestamps()
    end
  end
end
