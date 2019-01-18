defmodule BlockchainAPI.Explorer.Payment do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key false
  @derive {Phoenix.Param, key: :block_height}
  schema "payment_transactions" do
    field :amount, :integer
    field :fee, :integer
    field :nonce, :integer
    field :payee, :string
    field :payer, :string
    field :type, :string

    belongs_to :blocks, BlockchainAPI.Explorer.Block, foreign_key: :block_height, references: :height

    timestamps()
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:type, :amount, :payee, :payer, :fee, :nonce, :block_height])
    |> validate_required([:type, :amount, :payee, :payer, :fee, :nonce, :block_height])
  end
end
