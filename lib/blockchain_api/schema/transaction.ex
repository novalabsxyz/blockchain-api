defmodule BlockchainAPI.Schema.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Schema.Block, Schema.Transaction, Util}

  @fields [:id, :hash, :type, :block_height]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "transactions" do
    field :type, :string, null: false
    field :block_height, :integer, null: false
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "cleared"

    belongs_to :block, Block, define_field: false, foreign_key: :height

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
      Map.take(transaction, @fields)
      | hash: Util.bin_to_string(transaction.hash)
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
    %{type: "coinbase", hash: :blockchain_txn_coinbase_v1.hash(txn)}
  end

  def map(:blockchain_txn_consensus_group_v1, txn) do
    %{type: "election", hash: :blockchain_txn_consensus_group_v1.hash(txn)}
  end

  def map(:blockchain_txn_security_coinbase_v1, txn) do
    %{type: "security", hash: :blockchain_txn_security_coinbase_v1.hash(txn)}
  end

  def map(:blockchain_txn_security_exchange_v1, txn) do
    %{type: "security_exchange", hash: :blockchain_txn_security_exchange_v1.hash(txn)}
  end

  def map(:blockchain_txn_dc_coinbase_v1, txn) do
    %{type: "data_credit", hash: :blockchain_txn_dc_coinbase_v1.hash(txn)}
  end

  def map(:blockchain_txn_payment_v1, txn) do
    %{type: "payment", hash: :blockchain_txn_payment_v1.hash(txn)}
  end

  def map(:blockchain_txn_add_gateway_v1, txn) do
    %{type: "gateway", hash: :blockchain_txn_add_gateway_v1.hash(txn)}
  end

  def map(:blockchain_txn_assert_location_v1, txn) do
    %{type: "location", hash: :blockchain_txn_assert_location_v1.hash(txn)}
  end

  def map(:blockchain_txn_gen_gateway_v1, txn) do
    %{type: "gateway", hash: :blockchain_txn_gen_gateway_v1.hash(txn)}
  end

  def map(:blockchain_txn_poc_request_v1, txn) do
    %{type: "poc_request", hash: :blockchain_txn_poc_request_v1.hash(txn)}
  end

  def map(:blockchain_txn_poc_receipts_v1, txn) do
    %{type: "poc_receipts", hash: :blockchain_txn_poc_receipts_v1.hash(txn)}
  end

  def map(:blockchain_txn_rewards_v1, txn) do
    %{type: "rewards", hash: :blockchain_txn_rewards_v1.hash(txn)}
  end

  def map(:blockchain_txn_oui_v1, txn) do
    %{type: "oui", hash: :blockchain_txn_oui_v1.hash(txn)}
  end

  def map(:blockchain_txn_payment_v2, txn) do
    %{type: "payment_v2", hash: :blockchain_txn_payment_v2.hash(txn)}
  end
end
