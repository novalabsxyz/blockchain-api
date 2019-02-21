defmodule BlockchainAPI.Explorer.GatewayTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: [:id, :hash, :gateway, :owner, :fee]}
  schema "gateway_transactions" do
    field :gateway, :string, null: false
    field :owner, :string, null: false
    field :hash, :string, null: false
    field :fee, :integer, null: false, default: 0

    timestamps()
  end

  @doc false
  def changeset(gateway, attrs) do
    gateway
    |> cast(attrs, [:hash, :owner, :gateway, :fee])
    |> validate_required([:hash, :owner, :gateway, :fee])
    |> foreign_key_constraint(:hash)
    |> unique_constraint(:gateway)
  end
end
