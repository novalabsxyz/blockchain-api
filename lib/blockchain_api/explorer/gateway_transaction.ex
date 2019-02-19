defmodule BlockchainAPI.Explorer.GatewayTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: [:id, :hash, :gateway, :owner]}
  schema "gateway_transactions" do
    field :gateway, :string, null: false
    field :owner, :string, null: false
    field :hash, :string, null: false

    belongs_to :transaction, BlockchainAPI.Explorer.Transaction, foreign_key: :hash, references: :hash, define_field: false

    timestamps()
  end

  @doc false
  def changeset(gateway, attrs) do
    gateway
    |> cast(attrs, [:hash, :owner, :gateway])
    |> validate_required([:hash, :owner, :gateway])
    |> foreign_key_constraint(:hash)
    |> unique_constraint(:gateway)
  end
end
