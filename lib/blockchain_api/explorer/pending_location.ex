defmodule BlockchainAPI.Explorer.PendingLocation do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: [:id, :hash, :status, :nonce, :fee, :owner, :location, :gateway]}
  schema "pending_locations" do
    field :hash, :string, null: false
    field :status, :string, null: false, default: "pending"
    field :nonce, :integer, null: false, default: 0
    field :fee, :integer, null: false
    field :location, :string, null: false
    field :gateway, :string, null: false
    field :owner, :string, null: false

    timestamps()
  end

  @doc false
  def changeset(pending_location, attrs) do
    pending_location
    |> cast(attrs, [:hash, :status, :nonce, :fee, :location, :gateway, :owner])
    |> validate_required([:hash, :status, :nonce, :fee, :location, :gateway, :owner])
    |> foreign_key_constraint(:owner)
    |> unique_constraint(:unique_pending_location, name: :unique_pending_location)
  end
end
