defmodule BlockchainAPI.Schema.POCReceipt do
  use Ecto.Schema
  import Ecto.Changeset

  alias BlockchainAPI.{
    Util,
    Schema.POCReceipt,
    Schema.POCPathElement
  }

  @fields [
    :poc_path_elements_id,
    :gateway,
    :location,
    :timestamp,
    :signal,
    :data,
    :signature,
    :origin,
    :owner
  ]

  @derive {Jason.Encoder, only: @fields}
  schema "poc_receipts" do
    field :poc_path_elements_id, :integer, null: false
    field :gateway, :binary, null: false
    field :owner, :binary, null: false
    field :location, :string, null: false
    field :timestamp, :integer, null: false
    field :signal, :integer, null: false
    field :data, :binary, null: false
    field :signature, :binary, null: false
    field :origin, :string, null: false

    belongs_to :poc_path_elements, POCPathElement, define_field: false, foreign_key: :id

    timestamps()
  end

  @doc false
  def changeset(poc_receipt, attrs \\ %{}) do
    poc_receipt
    |> cast(attrs, @fields)
    |> foreign_key_constraint(:poc_path_elements_id)
  end

  def encode_model(poc_receipt) do
    {lat, lng} = Util.h3_to_lat_lng(poc_receipt.location)

    poc_receipt
    |> Map.take(@fields)
    |> Map.merge(%{
      gateway: Util.bin_to_string(poc_receipt.gateway),
      owner: Util.bin_to_string(poc_receipt.owner),
      signature: Util.bin_to_string(poc_receipt.signature),
      data: Base.encode64(poc_receipt.data),
      lat: lat,
      lng: lng
    })
  end

  def map(id, rx_loc, rx_owner, poc_receipt) do
    %{
      poc_path_elements_id: id,
      owner: rx_owner,
      gateway: :blockchain_poc_receipt_v1.gateway(poc_receipt),
      location: Util.h3_to_string(rx_loc),
      timestamp: :blockchain_poc_receipt_v1.timestamp(poc_receipt),
      signal: :blockchain_poc_receipt_v1.signal(poc_receipt),
      data: :blockchain_poc_receipt_v1.data(poc_receipt),
      signature: :blockchain_poc_receipt_v1.signature(poc_receipt),
      origin: to_string(:blockchain_poc_receipt_v1.origin(poc_receipt))
    }
  end

  defimpl Jason.Encoder, for: POCReceipt do
    def encode(poc_receipt, opts) do
      poc_receipt
      |> POCReceipt.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
