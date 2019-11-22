defmodule BlockchainAPI.Repo.Migrations.AddPendingBundleTable do
  import Honeydew.EctoPollQueue.Migration
  import BlockchainAPI.Schema.PendingBundle, only: [submit_bundle_queue: 0]
  use Ecto.Migration

  def change do
    create table(:pending_bundles) do
      add :hash, :binary, null: false
      add :status, :string, null: false, default: "pending"
      add :txn, :binary, null: false
      add :txn_hashes, {:array, :binary}, null: false
      add :submit_height, :bigint, null: false, default: 0

      honeydew_fields(submit_bundle_queue())
      timestamps()
    end

    honeydew_indexes(:pending_bundles, submit_bundle_queue())

  end
end
