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
    :lng
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

    timestamps()
  end

  @doc false
  def changeset(hotspot, attrs) do
    hotspot
    |> cast(attrs, [:address, :owner, :location, :long_city, :long_country, :long_street, :long_state, :short_street, :short_city, :short_country, :short_state])
    |> validate_required([:address, :owner, :location, :long_city, :long_country, :long_street, :long_state, :short_street, :short_city, :short_country, :short_state])
    |> unique_constraint(:unique_hotspots)
    |> unique_constraint(:unique_city_hotspots)
  end

  def encode_model(hotspot) do
    {lat, lng} = Util.h3_to_lat_lng(hotspot.location)

    hotspot
    |> Map.take(@fields)
    |> Map.merge(%{
      address: Util.bin_to_string(hotspot.address),
      owner: Util.bin_to_string(hotspot.owner),
      lat: lat,
      lng: lng
    })
  end

  defimpl Jason.Encoder, for: Hotspot do
    def encode(hotspot, opts) do
      hotspot
      |> Hotspot.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(location_txn) do
    loc = :blockchain_txn_assert_location_v1.location(location_txn)

    case Util.reverse_geocode(loc) do
      {:ok, loc_info_map} ->
        Map.merge(
        %{
          address: :blockchain_txn_assert_location_v1.gateway(location_txn),
          owner: :blockchain_txn_assert_location_v1.owner(location_txn),
          location: Util.h3_to_string(loc)
        }, loc_info_map)
      error ->
        # XXX: What if googleapi lookup fails!
        error
    end
  end
end
