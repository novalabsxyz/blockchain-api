defmodule BlockchainAPI.Explorer.AccountTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "account_transactions" do
    field :account_address, :string, primary_key: true
    field :txn_hash, :string, primary_key: true

    belongs_to :account, BlockchainAPI.Explorer.Account, foreign_key: :address, references: :address, define_field: false
    belongs_to :transaction, BlockchainAPI.Explorer.Transaction, foreign_key: :hash, references: :hash, define_field: false

    timestamps()
  end

  @doc false
  def changeset(account_transaction, attrs) do
    account_transaction
    |> cast(attrs, [:account_address, :txn_hash])
    |> validate_required([:account_address, :txn_hash])
    |> foreign_key_constraint(:hash)
    |> foreign_key_constraint(:address)
  end
end
