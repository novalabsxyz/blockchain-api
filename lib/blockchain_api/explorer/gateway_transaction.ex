defmodule BlockchainAPI.Explorer.GatewayTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @derive {Phoenix.Param, key: :gateway_hash}
  @derive {Jason.Encoder, only: [:id, :gateway_hash, :gateway, :owner]}
  schema "gateway_transactions" do
    field :gateway, :string, null: false
    field :owner, :string, null: false
    field :gateway_hash, :string, null: false

    belongs_to :transaction, BlockchainAPI.Explorer.Transaction, foreign_key: :hash, references: :hash, define_field: false

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
