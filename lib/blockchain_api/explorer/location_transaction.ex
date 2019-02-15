defmodule BlockchainAPI.Explorer.LocationTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: [:id, :hash, :fee, :gateway, :location, :nonce, :owner]}
  schema "location_transactions" do
    field :fee, :integer, null: false
    field :gateway, :string, null: false
    field :location, :string, null: false
    field :nonce, :integer, null: false
    field :owner, :string, null: false
    field :hash, :string, null: false

    belongs_to :transaction, BlockchainAPI.Explorer.Transaction, foreign_key: :hash, references: :hash, define_field: false
    belongs_to :gateway_transaction, BlockchainAPI.Explorer.GatewayTransaction, foreign_key: :gateway, references: :gateway, define_field: false

    timestamps()
  end

  @doc false
  def changeset(gateway_location, attrs) do
    gateway_location
    |> cast(attrs, [:hash, :gateway, :owner, :location, :nonce, :fee])
    |> validate_required([:hash, :gateway, :owner, :location, :nonce, :fee])
    |> foreign_key_constraint(:hash)
    |> foreign_key_constraint(:gateway)

  end
end
