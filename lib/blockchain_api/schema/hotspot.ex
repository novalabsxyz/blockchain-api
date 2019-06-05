defmodule BlockchainAPI.Schema.Hotspot do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.Hotspot}
  @fields [
    :id,
    :address,
    :owner,
    :location,
    :long_city,
    :long_street,
    :short_street,
    :long_state,
    :long_country,
    :short_city,
    :short_state,
    :short_country,
    :lat,
    :lng,
    :score,
    :score_update_height
  ]

  @derive {Phoenix.Param, key: :address}
  @derive {Jason.Encoder, only: @fields}
  schema "hotspots" do
    field :address, :binary, null: false
    field :owner, :binary, null: false
    field :location, :string, null: false
    field :long_street, :string, null: false
    field :long_city, :string, null: false
    field :long_state, :string, null: false
    field :long_country, :string, null: false
    field :short_street, :string, null: false
    field :short_city, :string, null: false
    field :short_state, :string, null: false
    field :short_country, :string, null: false
    field :score, :float, null: false, default: 0.0
    field :score_update_height, :integer, null: false, default: 0

    timestamps()
  end

  @doc false
  def changeset(hotspot, attrs) do
    hotspot
    |> cast(attrs,
      [:address,
      :owner,
      :location,
      :long_city,
      :long_country,
      :long_street,
      :long_state,
      :short_street,
      :short_city,
      :short_country,
      :short_state,
      :score,
      :score_update_height])
    |> validate_required([:address, :owner, :score, :score_update_height])
    |> unique_constraint(:unique_hotspots)
  end

  def encode_model(hotspot) do
    score = Decimal.from_float(hotspot.score) |> Decimal.round(4) |> Decimal.to_float()
    {lat, lng} = Util.h3_to_lat_lng(hotspot.location)

    hotspot
    |> Map.take(@fields)
    |> Map.merge(%{
      address: Util.bin_to_string(hotspot.address),
      owner: Util.bin_to_string(hotspot.owner),
      lat: lat,
      lng: lng,
      score: score
    })
  end

  defimpl Jason.Encoder, for: Hotspot do
    def encode(hotspot, opts) do
      hotspot
      |> Hotspot.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(:blockchain_txn_gen_gateway_v1, txn, _ledger) do
    case :blockchain_txn_gen_gateway_v1.location(txn) do
      :undefined ->
        %{
          address: :blockchain_txn_gen_gateway_v1.gateway(txn),
          owner: :blockchain_txn_gen_gateway_v1.owner(txn),
          location: nil,
          score: :blockchain_txn_gen_gateway_v1.score(txn)
        }
      loc ->
        case Util.reverse_geocode(loc) do
          {:ok, loc_info_map} ->
            Map.merge(
              %{
                address: :blockchain_txn_gen_gateway_v1.gateway(txn),
                owner: :blockchain_txn_gen_gateway_v1.owner(txn),
                location: Util.h3_to_string(loc),
                score: :blockchain_txn_gen_gateway_v1.score(txn)
              }, loc_info_map)
          error ->
            # XXX: What if googleapi lookup fails!
            error
        end
    end
  end

  def map(:blockchain_txn_add_gateway_v1, txn, _ledger) do
    %{
      address: :blockchain_txn_add_gateway_v1.gateway(txn),
      owner: :blockchain_txn_add_gateway_v1.owner(txn),
      location: nil
    }
  end

  def map(:blockchain_txn_assert_location_v1, txn, ledger) do
    address = :blockchain_txn_assert_location_v1.gateway(txn)
    owner = :blockchain_txn_assert_location_v1.owner(txn)
    case :blockchain_ledger_v1.gateway_score(address, ledger) do
      {:error, _}=error ->
        error
      {:ok, score} ->
        case :blockchain_txn_assert_location_v1.location(txn) do
          :undefined ->
            %{address: address, owner: owner, location: nil, score: score}
          loc ->
            case Util.reverse_geocode(loc) do
              {:ok, loc_info_map} ->
                Map.merge(%{address: address, owner: owner, location: Util.h3_to_string(loc), score: score}, loc_info_map)
              error ->
                # XXX: What if googleapi lookup fails!
                error
            end
        end
    end
  end
end
