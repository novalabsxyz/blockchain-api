defmodule BlockchainAPI.Explorer.PendingTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: [:id, :hash, :status, :account_address, :type, :nonce]}
  schema "pending_transactions" do
    field :hash, :string, null: false
    field :status, :string, null: false, default: "pending"
    field :type, :string, null: false
    field :nonce, :integer, null: false
    field :account_address, :string, null: false

    timestamps()
  end

  @doc false
  def changeset(pending_txn, attrs) do
    pending_txn
    |> cast(attrs, [:hash, :status, :account_address, :type, :nonce])
    |> validate_required([:hash, :status, :account_address, :type, :nonce])
    |> foreign_key_constraint(:account_address)
    |> unique_constraint(:unique_account_pending_txn, name: :unique_account_pending_txn)
  end
end
