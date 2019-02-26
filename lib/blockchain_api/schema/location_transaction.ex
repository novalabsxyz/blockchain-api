defmodule BlockchainAPI.Schema.LocationTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.LocationTransaction}
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

  def map(txn) do
    %{
      owner: :blockchain_txn_assert_location_v1.owner(txn),
      gateway: :blockchain_txn_assert_location_v1.gateway(txn),
      nonce: :blockchain_txn_assert_location_v1.nonce(txn),
      fee: :blockchain_txn_assert_location_v1.fee(txn),
      location: to_string(:h3.to_string(:blockchain_txn_assert_location_v1.location(txn))),
    }
  end
end
