defmodule BlockchainAPI.Schema.PendingLocation do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util,
    Schema.PendingLocation,
    Schema.PendingTransaction
  }

  @fields [
    :pending_transactions_hash,
    :status,
    :nonce,
    :fee,
    :owner,
    :location,
    :gateway]

  @derive {Jason.Encoder, only: @fields}
  schema "pending_locations" do
    field :fee, :integer, null: false
    field :gateway, :binary, null: false
    field :location, :string, null: false
    field :nonce, :integer, null: false, default: 0
    field :owner, :binary, null: false
    field :pending_transactions_hash, :binary, null: false
    field :status, :string, null: false, default: "pending"

    belongs_to :pending_transactions, PendingTransaction, define_field: false, foreign_key: :hash

    timestamps()
  end

  @doc false
  def changeset(pending_location, attrs) do
    pending_location
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:owner)
    |> foreign_key_constraint(:pending_transactions_hash)
    |> unique_constraint(:unique_pending_location, name: :unique_pending_location)
  end

  def encode_model(pending_location) do
    pending_location
    |> Map.take(@fields)
    |> Map.merge(%{
      owner: Util.bin_to_string(pending_location.owner),
      gateway: Util.bin_to_string(pending_location.gateway),
      pending_transactions_hash: Util.bin_to_string(pending_location.pending_transactions_hash),
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

  def map(hash, txn) do
    %{
      pending_transactions_hash: hash,
      fee: :blockchain_txn_assert_location_v1.fee(txn),
      gateway: :blockchain_txn_assert_location_v1.gateway(txn),
      location: Util.h3_to_string(:blockchain_txn_assert_location_v1.location(txn)),
      nonce: :blockchain_txn_assert_location_v1.nonce(txn),
      owner: :blockchain_txn_assert_location_v1.owner(txn),
      status: "pending"
    }
  end
end
