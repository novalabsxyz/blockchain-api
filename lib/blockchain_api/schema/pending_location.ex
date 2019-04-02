defmodule BlockchainAPI.Schema.PendingLocation do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.PendingLocation}
  @fields [:id, :hash, :status, :nonce, :fee, :owner, :location, :gateway]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "pending_locations" do
    field :fee, :integer, null: false
    field :gateway, :binary, null: false
    field :location, :string, null: false
    field :nonce, :integer, null: false, default: 0
    field :owner, :binary, null: false
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "pending"

    timestamps()
  end

  @doc false
  def changeset(pending_location, attrs) do
    pending_location
    |> cast(attrs, [:hash, :status, :nonce, :fee, :location, :gateway, :owner])
    |> validate_required([:hash, :status, :nonce, :fee, :location, :gateway, :owner])
    |> foreign_key_constraint(:owner)
    |> unique_constraint(:unique_pending_location, name: :unique_pending_location)
  end

  def encode_model(pending_location) do
    pending_location
    |> Map.take(@fields)
    |> Map.merge(%{
      owner: Util.bin_to_string(pending_location.owner),
      gateway: Util.bin_to_string(pending_location.gateway),
      hash: Util.bin_to_string(pending_location.hash),
      type: "location"
    })
  end

  defimpl Jason.Encoder, for: PendingLocation do
    def encode(pending_location, opts) do
      pending_location
      |> PendingLocation.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
