defmodule BlockchainAPI.Explorer.GatewayTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:gateway_hash, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :gateway_hash}
  schema "gateway_transactions" do
    field :gateway, :string
    field :owner, :string
    # field :gateway_hash, :string

    belongs_to :transactions, BlockchainAPI.Explorer.Transaction, foreign_key: :hash, references: :hash, define_field: false

    timestamps()
  end

  @doc false
  def changeset(gateway, attrs) do
    gateway
    |> cast(attrs, [:gateway_hash, :owner, :gateway])
    |> validate_required([:gateway_hash, :owner, :gateway])
    |> foreign_key_constraint(:gateway_hash)
  end
end
