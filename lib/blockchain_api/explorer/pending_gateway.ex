defmodule BlockchainAPI.Explorer.PendingGateway do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: [:id, :hash, :status, :owner, :gateway, :fee]}
  schema "pending_gateways" do
    field :hash, :string, null: false
    field :status, :string, null: false, default: "pending"
    field :gateway, :string, null: false
    field :owner, :string, null: false
    field :fee, :integer, null: false, default: 0

    timestamps()
  end

  @doc false
  def changeset(pending_gateway, attrs) do
    pending_gateway
    |> cast(attrs, [:hash, :status, :gateway, :owner, :fee])
    |> validate_required([:hash, :status, :gateway, :owner, :fee])
    |> foreign_key_constraint(:owner)
    |> unique_constraint(:unique_pending_gateway, name: :unique_pending_gateway)
  end
end
