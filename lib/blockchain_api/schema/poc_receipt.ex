defmodule BlockchainAPI.Schema.POCReceipt do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.POCReceipt}

  @fields [
    :poc_path_elements_id,
    :gateway,
    :timestamp,
    :signal,
    :data,
    :signature,
    :origin
  ]

  @derive {Jason.Encoder, only: @fields}
  schema "poc_receipts" do
    field :poc_path_elements_id, :integer, null: false
    field :gateway, :binary, null: false
    field :timestamp, :integer, null: false
    field :signal, :integer, null: false
    field :data, :binary, null: false
    field :signature, :binary, null: false
    field :origin, :string, null: false

    timestamps()
  end

  @doc false
  def changeset(poc_receipt, attrs \\ %{}) do
    poc_receipt
    |> cast(attrs, @fields)
    |> foreign_key_constraint(:poc_path_elements_id)
  end

  def encode_model(poc_receipt) do
    @fields
    |> Map.take(poc_receipt)
    |> Map.merge(%{
      gateway: Util.bin_to_string(poc_receipt.gateway),
      signature: Util.bin_to_string(poc_receipt.signature),
      data: Base.encode64(poc_receipt.data)
    })
  end

  def map(id, poc_receipt) do

    IO.inspect poc_receipt

    %{
      poc_path_elements_id: id,
      gateway: :blockchain_poc_receipt_v1.gateway(poc_receipt),
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
