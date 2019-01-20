defmodule BlockchainAPI.Explorer.LocationTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:location_hash, :string, autogenerate: false}
  schema "location_transactions" do
    field :fee, :integer
    field :gateway, :string
    field :location, :string
    field :nonce, :integer
    field :owner, :string

    belongs_to :transactions, BlockchainAPI.Explorer.Transaction, type: :string, primary_key: true, foreign_key: :location_hash, define_field: false

    timestamps()
  end

  @doc false
  def changeset(gateway_location, attrs) do
    gateway_location
    |> cast(attrs, [:gateway, :owner, :location, :nonce, :fee])
    |> validate_required([:gateway, :owner, :location, :nonce, :fee])
  end
end
