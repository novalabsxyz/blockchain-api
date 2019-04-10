defmodule BlockchainAPI.Schema.POCRequestTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.POCRequestTransaction}
  @fields [:challenger, :location, :hash, :signature, :fee, :onion]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "poc_request_transactions" do
    field :challenger, :binary, null: false
    field :location, :string, null: false
    field :hash, :binary, null: false
    field :signature, :binary, null: false
    field :fee, :integer, null: false
    field :onion, :binary, null: false

    timestamps()
  end

  @doc false
  def changeset(poc_request, attrs) do
    poc_request
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:hash)
    |> foreign_key_constraint(:challenger)
  end

  def encode_model(poc_request) do
    {lat, lng} = Util.h3_to_lat_lng(poc_request.location)

    poc_request
    |> Map.take(@fields)
    |> Map.merge(%{
      hash: Util.bin_to_string(poc_request.hash),
      challenger: Util.bin_to_string(poc_request.challenger),
      signature: Util.bin_to_string(poc_request.signature),
      onion: Util.bin_to_string(poc_request.onion),
      lat: lat,
      lng: lng
    })
  end

  defimpl Jason.Encoder, for: POCRequestTransaction do
    def encode(poc_request, opts) do
      poc_request
      |> POCRequestTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(challenger_loc, txn) do
    %{
      challenger: :blockchain_txn_poc_request_v1.challenger(txn),
      fee: :blockchain_txn_poc_request_v1.fee(txn),
      signature: :blockchain_txn_poc_request_v1.signature(txn),
      onion: :blockchain_txn_poc_request_v1.onion_key_hash(txn),
      hash: :blockchain_txn_poc_request_v1.hash(txn),
      location: Util.h3_to_string(challenger_loc),
    }
  end
end
