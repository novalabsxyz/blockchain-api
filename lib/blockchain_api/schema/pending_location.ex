defmodule BlockchainAPI.Schema.PendingLocation do
  use Ecto.Schema
  import Ecto.Changeset
  import Honeydew.EctoPollQueue.Schema
  alias BlockchainAPI.{Util, Schema.PendingLocation}

  @fields [
    :hash,
    :status,
    :nonce,
    :fee,
    :owner,
    :location,
    :gateway,
    :txn,
    :submit_height
  ]

  @submit_location_queue :submit_location_queue

  @derive {Jason.Encoder, only: @fields}
  schema "pending_locations" do
    field :fee, :integer, null: false
    field :gateway, :binary, null: false
    field :location, :string, null: false
    field :nonce, :integer, null: false, default: 0
    field :owner, :binary, null: false
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "pending"
    field :txn, :binary, null: false
    field :submit_height, :integer, null: false, default: 0

    honeydew_fields(@submit_location_queue)

    timestamps()
  end

  @doc false
  def changeset(pending_location, attrs) do
    pending_location
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:owner)
    |> unique_constraint(:unique_pending_location, name: :unique_pending_location)
  end

  def encode_model(pending_location) do
    pending_location
    |> Map.take(@fields)
    |> Map.drop([:txn, :submit_height])
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

  def map(txn, submit_height) do
    %{
      hash: :blockchain_txn_assert_location_v1.hash(txn),
      fee: :blockchain_txn_assert_location_v1.fee(txn),
      gateway: :blockchain_txn_assert_location_v1.gateway(txn),
      location: Util.h3_to_string(:blockchain_txn_assert_location_v1.location(txn)),
      nonce: :blockchain_txn_assert_location_v1.nonce(txn),
      owner: :blockchain_txn_assert_location_v1.owner(txn),
      status: "pending",
      txn: :blockchain_txn.serialize(txn),
      submit_height: submit_height
    }
  end

  def submit_location_queue, do: @submit_location_queue
end
