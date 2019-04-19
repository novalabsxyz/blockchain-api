defmodule BlockchainAPI.Schema.PendingCoinbase do
  use Ecto.Schema
  import Ecto.Changeset

  alias BlockchainAPI.{Util,
    Schema.PendingCoinbase,
    Schema.PendingTransaction
  }

  @fields [:payee, :pending_transactions_hash, :status, :amount]

  @derive {Jason.Encoder, only: @fields}
  schema "pending_coinbases" do
    field :pending_transactions_hash, :binary, null: false
    field :status, :string, null: false, default: "pending"
    field :amount, :integer, null: false, default: 0
    field :payee, :binary, null: false

    belongs_to :pending_transactions, PendingTransaction, define_field: false, foreign_key: :hash

    timestamps()
  end

  @doc false
  def changeset(pending_coinbase, attrs) do
    pending_coinbase
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:pending_transactions_hash)
    |> unique_constraint(:unique_pending_coinbase, name: :unique_pending_coinbase)
  end

  def encode_model(pending_coinbase) do
    pending_coinbase
    |> Map.take(@fields)
    |> Map.merge(%{
      pending_transactions_hash: Util.bin_to_string(pending_coinbase.pending_transactions_hash),
      hash: Util.bin_to_string(pending_coinbase.pending_transactions_hash),
      payee: Util.bin_to_string(pending_coinbase.payee),
      type: "coinbase"
    })
  end

  defimpl Jason.Encoder, for: PendingCoinbase do
    def encode(pending_coinbase, opts) do
      pending_coinbase
      |> PendingCoinbase.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(hash, txn) do
    %{
      pending_transactions_hash: hash,
      amount: :blockchain_txn_coinbase_v1.amount(txn),
      status: "pending",
      payee: :blockchain_txn_coinbase_v1.payee(txn),
    }
  end

end
