defmodule BlockchainAPI.Schema.POCWitness do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.POCWitness}

  @fields [
    :poc_path_elements_id,
    :gateway,
    :location,
    :timestamp,
    :signal,
    :packet_hash,
    :signature,
  ]

  @derive {Jason.Encoder, only: @fields}
  schema "poc_witnesses" do
    field :poc_path_elements_id, :integer, null: false
    field :gateway, :binary, null: false
    field :location, :string, null: false
    field :timestamp, :integer, null: false
    field :signal, :integer, null: false
    field :packet_hash, :binary, null: false
    field :signature, :binary, null: false

    timestamps()
  end

  @doc false
  def changeset(poc_witness, attrs \\ %{}) do
    poc_witness
    |> cast(attrs, @fields)
    |> foreign_key_constraint(:poc_path_elements_id)
  end

  def encode_model(poc_witness) do
    {lat, lng} = Util.h3_to_lat_lng(poc_witness.location)

    @fields
    |> Map.take(poc_witness)
    |> Map.merge(%{
      gateway: Util.bin_to_string(poc_witness.gateway),
      signature: Util.bin_to_string(poc_witness.signature),
      packet_hash: Base.encode64(poc_witness.packet_hash),
      lat: lat,
      lng: lng
    })
  end

  def map(id, wx_loc, poc_witness) do
    %{
      poc_path_elements_id: id,
      gateway: :blockchain_poc_witness_v1.gateway(poc_witness),
      location: Util.h3_to_string(wx_loc),
      timestamp: :blockchain_poc_witness_v1.timestamp(poc_witness),
      signal: :blockchain_poc_witness_v1.signal(poc_witness),
      packet_hash: :blockchain_poc_witness_v1.packet_hash(poc_witness),
      signature: :blockchain_poc_witness_v1.signature(poc_witness),
    }
  end

  defimpl Jason.Encoder, for: POCWitness do
    def encode(poc_witness, opts) do
      poc_witness
      |> POCWitness.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
