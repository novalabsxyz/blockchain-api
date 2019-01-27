defmodule BlockchainAPI.Explorer.LocationTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:location_hash, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :location_hash}
  @derive {Poison.Encoder, only: [:location_hash, :fee, :gateway, :location, :nonce, :owner]}
  schema "location_transactions" do
    field :fee, :integer
    field :gateway, :string
    field :location, :string
    field :nonce, :integer
    field :owner, :string

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
