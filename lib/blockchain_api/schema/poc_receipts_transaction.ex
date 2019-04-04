defmodule BlockchainAPI.Schema.POCReceiptsTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.POCReceiptsTransaction}

  @fields [:challenger, :hash, :signature, :fee, :onion]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "poc_receipts_transactions" do
    field :challenger, :binary, null: false
    field :hash, :binary, null: false
    field :signature, :binary, null: false
    field :fee, :integer, null: false
    field :onion, :binary, null: false

    timestamps()
  end

  @doc false
  def changeset(poc_receipts, attrs) do
    poc_receipts
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:hash)
    |> foreign_key_constraint(:challenger)
  end

  def encode_model(poc_receipts) do
    @fields
    |> Map.take(poc_receipts)
    |> Map.merge(%{
      hash: Util.bin_to_string(poc_receipts.transaction_hash),
      challenger: Util.bin_to_string(poc_receipts.challenger),
      signature: Util.bin_to_string(poc_receipts.signature),
      onion: Util.bin_to_string(poc_receipts.onion)
    })
  end

  defimpl Jason.Encoder, for: POCReceiptsTransaction do
    def encode(poc_receipts, opts) do
      poc_receipts
      |> POCReceiptsTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn) do
    %{
      challenger: :blockchain_txn_poc_receipts_v1.challenger(txn),
      fee: :blockchain_txn_poc_receipts_v1.fee(txn),
      signature: :blockchain_txn_poc_receipts_v1.signature(txn),
      onion: :blockchain_txn_poc_receipts_v1.onion_key_hash(txn),
      hash: :blockchain_txn_poc_receipts_v1.hash(txn)
    }
  end
end
