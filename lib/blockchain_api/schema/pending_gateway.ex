defmodule BlockchainAPI.Schema.PendingGateway do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util,
    Schema.PendingGateway,
    Schema.PendingTransaction
  }

  @fields [
    :pending_transactions_hash,
    :status,
    :owner,
    :gateway,
    :fee,
    :amount]

  @derive {Jason.Encoder, only: @fields}
  schema "pending_gateways" do
    field :pending_transactions_hash, :binary, null: false
    field :status, :string, null: false, default: "pending"
    field :gateway, :binary, null: false
    field :owner, :binary, null: false
    field :fee, :integer, null: false, default: 0
    field :amount, :integer, null: false, default: 0

    belongs_to :pending_transactions, PendingTransaction, define_field: false, foreign_key: :hash

    timestamps()
  end

  @doc false
  def changeset(pending_gateway, attrs) do
    pending_gateway
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:owner)
    |> foreign_key_constraint(:pending_transactions_hash)
    |> unique_constraint(:unique_pending_gateway, name: :unique_pending_gateway)
  end

  def encode_model(pending_gateway) do
    pending_gateway
    |> Map.take(@fields)
    |> Map.merge(%{
      owner: Util.bin_to_string(pending_gateway.owner),
      gateway: Util.bin_to_string(pending_gateway.gateway),
      pending_transactions_hash: Util.bin_to_string(pending_gateway.pending_transactions_hash),
      hash: Util.bin_to_string(pending_gateway.pending_transactions_hash),
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

  def map(hash, txn) do
    %{
      pending_transactions_hash: hash,
      status: "pending",
      owner: :blockchain_txn_add_gateway_v1.owner(txn),
      gateway: :blockchain_txn_add_gateway_v1.gateway(txn),
      fee: :blockchain_txn_add_gateway_v1.fee(txn),
      amount: :blockchain_txn_add_gateway_v1.amount(txn),
    }
  end
end
