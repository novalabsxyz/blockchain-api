defmodule BlockchainAPI.Schema.GatewayTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.GatewayTransaction}
  @fields [:id, :hash, :gateway, :owner, :fee, :amount]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "gateway_transactions" do
    field :gateway, :binary, null: false
    field :owner, :binary, null: false
    field :hash, :binary, null: false
    field :fee, :integer, null: false, default: 0
    field :amount, :integer, null: false, default: 0

    timestamps()
  end

  @doc false
  def changeset(gateway, attrs) do
    gateway
    |> cast(attrs, [:hash, :owner, :gateway, :fee, :amount])
    |> validate_required([:hash, :owner, :gateway, :fee, :amount])
    |> foreign_key_constraint(:hash)
    |> unique_constraint(:gateway)
  end

  def encode_model(gateway) do
    %{
      Map.take(gateway, @fields) |
      owner: Util.bin_to_string(gateway.owner),
      hash: Util.bin_to_string(gateway.hash),
      gateway: Util.bin_to_string(gateway.gateway)
    }
  end

  defimpl Jason.Encoder, for: GatewayTransaction do
    def encode(gateway, opts) do
      gateway
      |> GatewayTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn) do
    %{
      owner: :blockchain_txn_add_gateway_v1.owner(txn),
      gateway: :blockchain_txn_add_gateway_v1.gateway(txn),
      fee: :blockchain_txn_add_gateway_v1.fee(txn),
      amount: :blockchain_txn_add_gateway_v1.amount(txn),
      hash: :blockchain_txn_add_gateway_v1.hash(txn)
    }
  end

  def map(:genesis, txn) do
    %{
      owner: :blockchain_txn_gen_gateway_v1.owner(txn),
      gateway: :blockchain_txn_gen_gateway_v1.gateway(txn),
      fee: :blockchain_txn_gen_gateway_v1.fee(txn),
      hash: :blockchain_txn_gen_gateway_v1.hash(txn)
    }
  end
end
