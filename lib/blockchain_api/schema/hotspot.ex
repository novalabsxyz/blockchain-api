defmodule BlockchainAPI.Schema.Hotspot do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.Hotspot}
  @fields [
    :id,
    :address,
    :owner,
    :location,
    :city,
    :street,
    :state,
    :country,
    :lat,
    :lng
  ]

  @derive {Phoenix.Param, key: :address}
  @derive {Jason.Encoder, only: @fields}
  schema "hotspots" do
    field :address, :binary, null: false
    field :owner, :binary, null: false
    field :location, :string, null: false
    field :street, :string, null: false
    field :city, :string, null: false
    field :state, :string, null: false
    field :country, :string, null: false

    timestamps()
  end

  @doc false
  def changeset(hotspot, attrs) do
    hotspot
    |> cast(attrs, [:address, :owner, :location, :city, :country, :street, :state])
    |> validate_required([:address, :owner, :location, :city, :country, :street, :state])
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
      {:ok, {street, city, state, country}} ->
        %{
          address: :blockchain_txn_assert_location_v1.gateway(location_txn),
          owner: :blockchain_txn_assert_location_v1.owner(location_txn),
          location: Util.h3_to_string(loc),
          city: city,
          street: street,
          state: state,
          country: country
        }
      error ->
        # XXX: What if googleapi lookup fails!
        error
    end
  end
end
