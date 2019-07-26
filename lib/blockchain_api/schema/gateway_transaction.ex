defmodule BlockchainAPI.Schema.GatewayTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.GatewayTransaction}
  @fields [:id, :hash, :gateway, :owner, :payer, :fee, :staking_fee, :height, :time]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "gateway_transactions" do
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "cleared"
    field :gateway, :binary, null: false
    field :owner, :binary, null: false
    field :payer, :binary, null: true
    field :fee, :integer, null: false, default: 0
    field :staking_fee, :integer, null: false, default: 1

    timestamps()
  end

  @doc false
  def changeset(gateway, attrs) do
    gateway
    |> cast(attrs, [:hash, :owner, :payer, :gateway, :fee, :staking_fee, :status])
    |> validate_required([:hash, :owner, :gateway, :fee, :staking_fee, :status])
    |> foreign_key_constraint(:hash)
    |> unique_constraint(:gateway)
  end

  def encode_model(gateway) do
    gateway
    |> Map.take(@fields)
    |> Map.merge(%{
      owner: Util.bin_to_string(gateway.owner),
      hash: Util.bin_to_string(gateway.hash),
      gateway: Util.bin_to_string(gateway.gateway),
      payer: Util.bin_to_string(gateway.payer),
      type: "gateway"
    })
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
      staking_fee: :blockchain_txn_add_gateway_v1.staking_fee(txn),
      hash: :blockchain_txn_add_gateway_v1.hash(txn),
      payer: :blockchain_txn_add_gateway_v1.payer(txn)
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
