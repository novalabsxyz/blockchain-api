defmodule BlockchainAPI.Explorer.GatewayLocation do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key false
  @derive {Phoenix.Param, key: :block_height}
  schema "assert_location_transactions" do
    field :fee, :integer
    field :gateway, :string
    field :location, :string
    field :nonce, :integer
    field :owner, :string
    field :type, :string
    field :hash, :string

    belongs_to :blocks, BlockchainAPI.Explorer.Block, foreign_key: :block_height, references: :height

    timestamps()
  end

  @doc false
  def changeset(gateway_location, attrs) do
    gateway_location
    |> cast(attrs, [:type, :gateway, :owner, :location, :nonce, :fee, :block_height, :hash])
    |> validate_required([:type, :gateway, :owner, :location, :nonce, :fee, :block_height, :hash])
  end
end
