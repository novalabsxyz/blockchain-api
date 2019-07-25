defmodule BlockchainAPI.Schema.POCReceiptsTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{
    Util,
    Schema.POCReceiptsTransaction,
    Schema.POCPathElement,
    Schema.POCRequestTransaction
  }

  @required_fields [
    :poc_request_transactions_id,
    :challenger,
    :challenger_loc,
    :hash,
    :signature,
    :fee,
    :onion,
    :challenger_owner
  ]

  @encoded_fields [
    :poc_request_transactions_id,
    :challenger,
    :challenger_loc,
    :hash,
    :signature,
    :fee,
    :onion,
    :challenger_owner
  ]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @required_fields}
  schema "poc_receipts_transactions" do
    field :poc_request_transactions_id, :integer, null: false
    field :challenger, :binary, null: false
    field :challenger_owner, :binary, null: false
    field :challenger_loc, :string, null: false
    field :hash, :binary, null: false
    field :signature, :binary, null: false
    field :fee, :integer, null: false
    field :onion, :binary, null: false

    has_many :poc_path_elements, POCPathElement, foreign_key: :poc_receipts_transactions_hash, references: :hash
    belongs_to :poc_request_transactions, POCRequestTransaction, define_field: false, foreign_key: :id

    timestamps()
  end

  @doc false
  def changeset(poc_receipts, attrs) do
    poc_receipts
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:hash)
    |> foreign_key_constraint(:challenger)
    |> foreign_key_constraint(:poc_request_transactions_id)
  end

  def encode_model(poc_receipts) do
    {lat, lng} = Util.h3_to_lat_lng(poc_receipts.challenger_loc)

    poc_receipts
    |> Map.take(@encoded_fields)
    |> Map.merge(%{
      challenge_id: poc_receipts.id,
      hash: Util.bin_to_string(poc_receipts.hash),
      challenger: Util.bin_to_string(poc_receipts.challenger),
      challenger_owner: Util.bin_to_string(poc_receipts.challenger_owner),
      challenger_lat: lat,
      challenger_lng: lng,
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

  def map(poc_request_id, challenger_loc, challenger_owner, txn) do
    %{
      poc_request_transactions_id: poc_request_id,
      challenger_loc: Util.h3_to_string(challenger_loc),
      challenger: :blockchain_txn_poc_receipts_v1.challenger(txn),
      challenger_owner: challenger_owner,
      fee: :blockchain_txn_poc_receipts_v1.fee(txn),
      signature: :blockchain_txn_poc_receipts_v1.signature(txn),
      onion: :blockchain_txn_poc_receipts_v1.onion_key_hash(txn),
      hash: :blockchain_txn_poc_receipts_v1.hash(txn)
    }
  end
end
