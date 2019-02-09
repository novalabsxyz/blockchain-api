defmodule BlockchainAPI.Explorer.LocationTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @derive {Phoenix.Param, key: :location_hash}
  @derive {Jason.Encoder, only: [:id, :location_hash, :fee, :gateway, :location, :nonce, :owner]}
  schema "location_transactions" do
    field :fee, :integer, null: false
    field :gateway, :string, null: false
    field :location, :string, null: false
    field :nonce, :integer, null: false
    field :owner, :string, null: false
    field :location_hash, :string, null: false

    belongs_to :transaction, BlockchainAPI.Explorer.Transaction, foreign_key: :hash, references: :hash, define_field: false

    timestamps()
  end

  @doc false
  def changeset(gateway_location, attrs) do
    gateway_location
    |> cast(attrs, [:location_hash, :gateway, :owner, :location, :nonce, :fee])
    |> validate_required([:location_hash, :gateway, :owner, :location, :nonce, :fee])
    |> foreign_key_constraint(:location_hash)

  end
end
