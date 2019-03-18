defmodule BlockchainAPI.Schema.POCRequestTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.POCRequestTransaction}
  @fields [:gateway, :hash, :signature, :fee, :onion]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "poc_request_transactions" do
    field :gateway, :binary, null: false
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
    |> foreign_key_constraint(:gateway)
  end

  def encode_model(poc_request) do
    %{
      Map.take(poc_request, @fields) |
      hash: Util.bin_to_string(poc_request.hash),
      gateway: Util.bin_to_string(poc_request.gateway),
      signature: Util.bin_to_string(poc_request.signature),
      onion: Util.bin_to_string(poc_request.onion)
    }
  end

  defimpl Jason.Encoder, for: POCRequestTransaction do
    def encode(poc_request, opts) do
      poc_request
      |> POCRequestTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn) do
    IO.inspect txn

    %{
      gateway: :blockchain_txn_poc_request_v1.gateway(txn),
      fee: :blockchain_txn_poc_request_v1.fee(txn),
      signature: :blockchain_txn_poc_request_v1.signature(txn),
      onion: :blockchain_txn_poc_request_v1.onion(txn),
      hash: :blockchain_txn_poc_request_v1.hash(txn)
    }
  end
end
