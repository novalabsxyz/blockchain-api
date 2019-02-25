defmodule BlockchainAPI.Explorer.LocationTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Explorer.LocationTransaction}
  @fields [:id, :hash, :fee, :gateway, :location, :nonce, :owner]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "location_transactions" do
    field :fee, :integer, null: false
    field :gateway, :binary, null: false
    field :location, :string, null: false
    field :nonce, :integer, null: false, default: 0
    field :owner, :binary, null: false
    field :hash, :binary, null: false

    timestamps()
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [:hash, :gateway, :owner, :location, :nonce, :fee])
    |> validate_required([:hash, :gateway, :owner, :location, :nonce, :fee])
    |> foreign_key_constraint(:hash)
    |> foreign_key_constraint(:gateway)
  end

  def encode_model(location) do
    %{
      Map.take(location, @fields) |
      owner: Util.bin_to_string(location.owner),
      hash: Util.bin_to_string(location.hash),
      gateway: Util.bin_to_string(location.gateway)
    }
  end

  defimpl Jason.Encoder, for: LocationTransaction do
    def encode(location, opts) do
      location
      |> LocationTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
