defmodule BlockchainAPI.Schema.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.Transaction}
  @fields [:id, :hash, :type, :block_height]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "transactions" do
    field :type, :string, null: false
    field :block_height, :integer, null: false
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "cleared"

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:hash, :type, :block_height, :status])
    |> validate_required([:hash, :type, :status])
    |> unique_constraint(:hash)
    |> foreign_key_constraint(:block_height)
  end

  def encode_model(transaction) do
    %{
      Map.take(transaction, @fields) |
      hash: Util.bin_to_string(transaction.hash)
    }
  end

  defimpl Jason.Encoder, for: Transaction do
    def encode(transaction, opts) do
      transaction
      |> Transaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(:blockchain_txn_coinbase_v1, txn) do
    %{type: "coinbase", status: "cleared", hash: :blockchain_txn_coinbase_v1.hash(txn)}
  end

  def map(:blockchain_txn_security_coinbase_v1, txn) do
    %{type: "security", status: "cleared", hash: :blockchain_txn_security_coinbase_v1.hash(txn)}
  end

  def map(:blockchain_txn_payment_v1, txn) do
    %{type: "payment", status: "cleared", hash: :blockchain_txn_payment_v1.hash(txn)}
  end

  def map(:blockchain_txn_add_gateway_v1, txn) do
    %{type: "gateway", status: "cleared", hash: :blockchain_txn_add_gateway_v1.hash(txn)}
  end

  def map(:blockchain_txn_assert_location_v1, txn) do
    %{type: "location", status: "cleared", hash: :blockchain_txn_assert_location_v1.hash(txn)}
  end

  def map(:blockchain_txn_gen_gateway_v1, txn) do
    %{type: "gateway", status: "cleared", hash: :blockchain_txn_gen_gateway_v1.hash(txn)}
  end

  def map(:blockchain_txn_poc_request_v1, txn) do
    %{type: "poc_request", hash: :blockchain_txn_poc_request_v1.hash(txn)}
  end

  def map(:blockchain_txn_poc_receipts_v1, txn) do
    %{type: "poc_receipts", hash: :blockchain_txn_poc_receipts_v1.hash(txn)}
  end
end
