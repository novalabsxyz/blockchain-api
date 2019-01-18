defmodule BlockchainAPI.Explorer.Block do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:height, :id, []}
  @derive {Phoenix.Param, key: :height}
  schema "blocks" do
    field :hash, :string
    field :round, :integer
    field :time, :integer

    has_many :coinbase_transactions, BlockchainAPI.Explorer.Coinbase
    has_many :payment_transactions, BlockchainAPI.Explorer.Payment
    has_many :add_gateway_transactions, BlockchainAPI.Explorer.Gateway
    has_many :assert_location_transactions, BlockchainAPI.Explorer.GatewayLocation

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:hash, :height, :round, :time])
    |> validate_required([:hash, :height, :round, :time])
    |> unique_constraint(:hash)
    |> unique_constraint(:height)
  end
end
