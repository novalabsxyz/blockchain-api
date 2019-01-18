defmodule BlockchainAPI.Explorer.Gateway do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key false
  @derive {Phoenix.Param, key: :block_height}
  schema "add_gateway_transactions" do
    field :gateway, :string
    field :owner, :string
    field :type, :string

    belongs_to :blocks, BlockchainAPI.Explorer.Block, foreign_key: :block_height, references: :height

    timestamps()
  end

  @doc false
  def changeset(gateway, attrs) do
    gateway
    |> cast(attrs, [:type, :owner, :gateway, :block_height])
    |> validate_required([:type, :owner, :gateway, :block_height])
  end
end
