defmodule BlockchainAPI.Schema.LocationTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.LocationTransaction}
  @fields [:id, :hash, :fee, :staking_fee, :gateway, :location, :nonce, :owner, :payer, :height, :time]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "location_transactions" do
    field :fee, :integer, null: false
    field :gateway, :binary, null: false
    field :location, :string, null: false
    field :nonce, :integer, null: false, default: 0
    field :owner, :binary, null: false
    field :payer, :binary, null: true
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "cleared"
    field :staking_fee, :integer, null: false, default: 1

    timestamps()
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [:hash, :gateway, :owner, :payer, :location, :nonce, :fee, :staking_fee, :status])
    |> validate_required([:hash, :gateway, :owner, :location, :nonce, :fee, :status])
    |> foreign_key_constraint(:hash)
    |> foreign_key_constraint(:gateway)
  end

  def encode_model(location) do
    {lat, lng} = Util.h3_to_lat_lng(location.location)

    payer =
      case location.payer do
        :undefined -> nil
        <<>> -> nil
        p -> Util.bin_to_string(p)
      end

    location
    |> Map.take(@fields)
    |> Map.merge(%{
      owner: Util.bin_to_string(location.owner),
      hash: Util.bin_to_string(location.hash),
      gateway: Util.bin_to_string(location.gateway),
      payer: payer,
      lat: lat,
      lng: lng,
      type: "location"
    })
  end

  defimpl Jason.Encoder, for: LocationTransaction do
    def encode(location, opts) do
      location
      |> LocationTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(:blockchain_txn_gen_gateway_v1, txn) do
    %{
      owner: :blockchain_txn_gen_gateway_v1.owner(txn),
      gateway: :blockchain_txn_gen_gateway_v1.gateway(txn),
      nonce: :blockchain_txn_gen_gateway_v1.nonce(txn),
      fee: :blockchain_txn_gen_gateway_v1.fee(txn),
      hash: :blockchain_txn_gen_gateway_v1.hash(txn),
      location: Util.h3_to_string(:blockchain_txn_gen_gateway_v1.location(txn))
    }
  end
  def map(:blockchain_txn_assert_location_v1, txn) do
    %{
      owner: :blockchain_txn_assert_location_v1.owner(txn),
      payer: :blockchain_txn_assert_location_v1.payer(txn),
      gateway: :blockchain_txn_assert_location_v1.gateway(txn),
      nonce: :blockchain_txn_assert_location_v1.nonce(txn),
      fee: :blockchain_txn_assert_location_v1.fee(txn),
      staking_fee: :blockchain_txn_assert_location_v1.staking_fee(txn),
      hash: :blockchain_txn_assert_location_v1.hash(txn),
      location: Util.h3_to_string(:blockchain_txn_assert_location_v1.location(txn))
    }
  end
end
