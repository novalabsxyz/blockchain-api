defmodule BlockchainAPI.Explorer.PendingTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: [:id, :hash]}
  schema "pending_transactions" do
    field :hash, :string, null: false
    field :status, :string, null: false, default: "pending"

    timestamps()
  end

  @doc false
  def changeset(pending_txn, attrs) do
    pending_txn
    |> cast(attrs, [:hash, :status])
    |> validate_required([:hash, :status])
  end
end
