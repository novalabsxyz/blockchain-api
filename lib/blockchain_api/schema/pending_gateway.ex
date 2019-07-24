defmodule BlockchainAPI.Schema.PendingGateway do
  use Ecto.Schema
  import Ecto.Changeset
  import Honeydew.EctoPollQueue.Schema
  alias BlockchainAPI.{Util, Schema.PendingGateway}

  @fields [
    :hash,
    :status,
    :owner,
    :gateway,
    :fee,
    :staking_fee,
    :txn,
    :submit_height
  ]

  @submit_gateway_queue :submit_gateway_queue

  @derive {Jason.Encoder, only: @fields}
  schema "pending_gateways" do
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "pending"
    field :gateway, :binary, null: false
    field :owner, :binary, null: false
    field :fee, :integer, null: false, default: 0
    field :staking_fee, :integer, null: false, default: 0
    field :txn, :binary, null: false
    field :submit_height, :integer, null: false, default: 0

    honeydew_fields(@submit_gateway_queue)

    timestamps()
  end

  @doc false
  def changeset(pending_gateway, attrs) do
    pending_gateway
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:owner)
    |> unique_constraint(:unique_pending_owner_gateway, name: :unique_pending_gateway_owner)
    |> unique_constraint(:unique_pending_gateway, name: :unique_pending_gateway)
  end

  def encode_model(pending_gateway) do
    pending_gateway
    |> Map.take(@fields)
    |> Map.drop([:txn, :submit_height])
    |> Map.merge(%{
      owner: Util.bin_to_string(pending_gateway.owner),
      gateway: Util.bin_to_string(pending_gateway.gateway),
      hash: Util.bin_to_string(pending_gateway.hash),
      type: "gateway"
    })
  end

  defimpl Jason.Encoder, for: PendingGateway do
    def encode(pending_gateway, opts) do
      pending_gateway
      |> PendingGateway.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn, submit_height) do
    %{
      status: "pending",
      hash: :blockchain_txn_add_gateway_v1.hash(txn),
      owner: :blockchain_txn_add_gateway_v1.owner(txn),
      gateway: :blockchain_txn_add_gateway_v1.gateway(txn),
      fee: :blockchain_txn_add_gateway_v1.fee(txn),
      staking_fee: :blockchain_txn_add_gateway_v1.staking_fee(txn),
      txn: :blockchain_txn.serialize(txn),
      submit_height: submit_height
    }
  end

  def submit_gateway_queue, do: @submit_gateway_queue
end
