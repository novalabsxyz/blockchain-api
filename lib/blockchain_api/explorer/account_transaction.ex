defmodule BlockchainAPI.Explorer.AccountTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Poison.Encoder, only: [:id, :account_address, :txn_hash, :txn_type]}
  schema "account_transactions" do
    field :account_address, :string, null: false
    field :txn_hash, :string, null: false
    field :txn_type, :string, null: false

    timestamps()
  end

  @doc false
  def changeset(account_transaction, attrs) do
    account_transaction
    |> cast(attrs, [:account_address, :txn_hash, :txn_type])
    |> validate_required([:account_address, :txn_hash, :txn_type])
    |> foreign_key_constraint(:hash)
    |> foreign_key_constraint(:address)
    |> unique_constraint(:unique_account_txn, name: :unique_account_txn)
  end
end
