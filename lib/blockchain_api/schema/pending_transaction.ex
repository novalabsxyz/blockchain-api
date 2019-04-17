defmodule BlockchainAPI.Schema.PendingTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util,
    Schema.PendingTransaction,
    Schema.PendingCoinbase,
    Schema.PendingPayment,
    Schema.PendingGateway,
    Schema.PendingLocation
  }
  @fields [:id, :hash, :type, :status]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "pending_transactions" do
    field :type, :string, null: false
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "pending"

    has_many :pending_payments, PendingPayment, foreign_key: :pending_transactions_hash, references: :hash
    has_many :pending_coinbases, PendingCoinbase, foreign_key: :pending_transactions_hash, references: :hash
    has_many :pending_gateways, PendingGateway, foreign_key: :pending_transactions_hash, references: :hash
    has_many :pending_locations, PendingLocation, foreign_key: :pending_transactions_hash, references: :hash
    timestamps()
  end

  @doc false
  def changeset(pending_transaction, attrs) do
    pending_transaction
    |> cast(attrs, [:hash, :type, :status])
    |> validate_required([:hash, :type, :status])
    |> unique_constraint(:hash)
  end

  def encode_model(pending_transaction) do
    %{
      Map.take(pending_transaction, @fields) |
      hash: Util.bin_to_string(pending_transaction.hash)
    }
  end

  defimpl Jason.Encoder, for: PendingTransaction do
    def encode(pending_transaction, opts) do
      pending_transaction
      |> PendingTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(:blockchain_txn_coinbase_v1, txn) do
    %{type: "coinbase", status: "pending", hash: :blockchain_txn_coinbase_v1.hash(txn)}
  end

  def map(:blockchain_txn_payment_v1, txn) do
    %{type: "payment", status: "pending", hash: :blockchain_txn_payment_v1.hash(txn)}
  end

  def map(:blockchain_txn_add_gateway_v1, txn) do
    %{type: "gateway", status: "pending", hash: :blockchain_txn_add_gateway_v1.hash(txn)}
  end

  def map(:blockchain_txn_assert_location_v1, txn) do
    %{type: "location", status: "pending", hash: :blockchain_txn_assert_location_v1.hash(txn)}
  end
end
