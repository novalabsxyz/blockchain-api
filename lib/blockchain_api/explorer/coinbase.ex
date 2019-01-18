defmodule BlockchainAPI.Explorer.Coinbase do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key false
  @derive {Phoenix.Param, key: :block_height}
  schema "coinbase_transactions" do
    field :amount, :integer
    field :payee, :string
    field :type, :string
    field :hash, :string

    belongs_to :blocks, BlockchainAPI.Explorer.Block, foreign_key: :block_height, references: :height

    timestamps()
  end

  @doc false
  def changeset(coinbase, attrs) do
    coinbase
    |> cast(attrs, [:type, :amount, :payee, :block_height, :hash])
    |> validate_required([:type, :amount, :payee, :block_height, :hash])
  end
end
