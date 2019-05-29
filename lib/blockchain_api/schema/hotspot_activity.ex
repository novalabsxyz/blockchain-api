defmodule BlockchainAPI.Schema.HotspotActivity do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.HotspotActivity}

  @fields [
    :id,
    :gateway,
    :poc_req_txn_hash,
    :poc_req_txn_block_height,
    :poc_rx_txn_hash,
    :poc_rx_txn_block_height,
    :poc_witness_id,
    :poc_rx_id,
    :poc_witness_challenge_id,
    :poc_rx_challenge_id,
    :poc_score
  ]

  @derive {Jason.Encoder, only: @fields}
  schema "hotspot_activity" do
    field :gateway, :binary, null: false
    field :poc_req_txn_hash, :binary, null: true
    field :poc_req_txn_block_height, :integer, null: true
    field :poc_rx_txn_hash, :binary, null: true
    field :poc_rx_txn_block_height, :integer, null: true
    field :poc_witness_id, :integer, null: true
    field :poc_rx_id, :integer, null: true
    field :poc_witness_challenge_id, :integer, null: true
    field :poc_rx_challenge_id, :integer, null: true
    field :poc_score, :float, null: false, default: 0.0

    timestamps()
  end

  @doc false
  def changeset(hotspot_activity, attrs) do
    hotspot_activity
    |> cast(attrs, @fields)
    |> validate_required([:gateway, :poc_score])
    |> foreign_key_constraint(:gateway)
    |> foreign_key_constraint(:poc_req_txn_hash)
    |> foreign_key_constraint(:poc_req_txn_block_height)
    |> foreign_key_constraint(:poc_rx_txn_hash)
    |> foreign_key_constraint(:poc_rx_txn_block_height)
    |> foreign_key_constraint(:poc_witness_id)
    |> foreign_key_constraint(:poc_rx_id)
    |> foreign_key_constraint(:poc_witness_challenge_id)
    |> foreign_key_constraint(:poc_rx_challenge_id)
  end

  def encode_model(hotspot_activity) do
    hotspot_activity
    |> Map.take(@fields)
    |> Map.merge(%{
      gateway: Util.bin_to_string(hotspot_activity.address),
      poc_req_txn_hash: Util.bin_to_string(hotspot_activity.poc_req_txn_hash),
      poc_rx_txn_hash: Util.bin_to_string(hotspot_activity.poc_rx_txn_hash),
    })
  end

  defimpl Jason.Encoder, for: HotspotActivity do
    def encode(hotspot_activity, opts) do
      hotspot_activity
      |> HotspotActivity.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
