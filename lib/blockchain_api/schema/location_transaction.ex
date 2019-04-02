defmodule BlockchainAPI.Schema.LocationTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.LocationTransaction}
  @fields [:id, :hash, :fee, :gateway, :location, :nonce, :owner, :height, :time]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "location_transactions" do
    field :fee, :integer, null: false
    field :gateway, :binary, null: false
    field :location, :string, null: false
    field :nonce, :integer, null: false, default: 0
    field :owner, :binary, null: false
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "cleared"

    timestamps()
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [:hash, :gateway, :owner, :location, :nonce, :fee, :status])
    |> validate_required([:hash, :gateway, :owner, :location, :nonce, :fee, :status])
    |> foreign_key_constraint(:hash)
    |> foreign_key_constraint(:gateway)
  end

  def encode_model(location) do
    location
    |> Map.take(@fields)
    |> Map.merge(%{
      owner: Util.bin_to_string(location.owner),
      hash: Util.bin_to_string(location.hash),
      gateway: Util.bin_to_string(location.gateway),
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

  def map(txn_mod, txn) do
    %{
      owner: txn_mod.owner(txn),
      gateway: txn_mod.gateway(txn),
      nonce: txn_mod.nonce(txn),
      fee: txn_mod.fee(txn),
      hash: txn_mod.hash(txn),
      location: Util.h3_to_string(txn_mod.location(txn))
    }
  end
end
