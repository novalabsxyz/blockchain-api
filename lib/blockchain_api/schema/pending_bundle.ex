defmodule BlockchainAPI.Schema.PendingBundle do
  use Ecto.Schema
  import Ecto.Changeset
  import Honeydew.EctoPollQueue.Schema

  alias BlockchainAPI.{Util, Schema.PendingBundle}

  @fields [
    :hash,
    :txn_hashes,
    :txn_types,
    :txn,
    :submit_height,
    :status
  ]

  @submit_bundle_queue :submit_bundle_queue

  @derive {Jason.Encoder, only: @fields}
  schema "pending_bundles" do
    field :hash, :binary, null: false
    field :txn_hashes, {:array, :binary}, null: false
    field :txn_types, {:array, :string}, null: false
    field :txn, :binary, null: false
    field :submit_height, :integer, null: false, default: 0
    field :status, :string, null: false, default: "pending"

    honeydew_fields(@submit_bundle_queue)

    timestamps()
  end

  @doc false
  def changeset(pending_bundle, attrs) do
    pending_bundle
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end

  def encode_model(pending_bundle) do
    pending_bundle
    |> Map.take(@fields)
    |> Map.drop([:txn, :submit_height])
    |> Map.merge(%{
      hash: Util.bin_to_string(pending_bundle.hash),
      txn_hashes: encode_txn_hashes(pending_bundle),
      txn_types: encode_txn_types(pending_bundle),
      type: "bundle"
    })
  end

  defimpl Jason.Encoder, for: PendingBundle do
    def encode(pending_bundle, opts) do
      pending_bundle
      |> PendingBundle.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn, submit_height) do
    %{
      hash: :blockchain_txn_bundle_v1.hash(txn),
      txn: :blockchain_txn.serialize(txn),
      txn_hashes: txn_hashes(txn),
      txn_types: txn_types(txn),
      submit_height: submit_height,
      status: "pending"
    }
  end

  defp txn_hashes(txn) do
    txn
    |> :blockchain_txn_bundle_v1.txns()
    |> Enum.map(fn(t) -> :blockchain_txn.hash(t) end)
  end

  defp txn_types(txn) do
    txn
    |> :blockchain_txn_bundle_v1.txns()
    |> Enum.map(fn(t) -> :blockchain_txn.type(t) end)
  end

  defp encode_txn_hashes(pending_bundle) do
    pending_bundle.txn_hashes
    |> Enum.map(fn(hash) -> Util.bin_to_string(hash) end)
  end

  defp encode_txn_types(pending_bundle) do
    pending_bundle.txn_types
    |> Enum.map(fn(type) -> Atom.to_string(type) end)
  end

  def submit_bundle_queue, do: @submit_bundle_queue
end
