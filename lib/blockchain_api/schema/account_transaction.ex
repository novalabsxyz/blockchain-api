defmodule BlockchainAPI.Schema.AccountTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.AccountTransaction}
  @fields [:id, :account_address, :txn_hash, :txn_type]

  @derive {Jason.Encoder, only: @fields}
  schema "account_transactions" do
    field :account_address, :binary, null: false
    field :txn_hash, :binary, null: false
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

  def encode_model(account_transaction) do
    %{Map.take(account_transaction, @fields) |
      txn_hash: Util.bin_to_string(account_transaction.txn_hash),
      account_address: Util.bin_to_string(account_transaction.account_address)
    }
  end

  defimpl Jason.Encoder, for: AccountTransaction do
    def encode(account_transaction, opts) do
      account_transaction
      |> AccountTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(account, txn) do
    %{
      account_address: account.address,
      txn_hash: txn.hash,
      txn_type: txn.type
    }
  end
end
