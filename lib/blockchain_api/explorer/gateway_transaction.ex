defmodule BlockchainAPI.Explorer.GatewayTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:gateway_hash, :string, autogenerate: false}
  schema "gateway_transactions" do
    field :gateway, :string
    field :owner, :string

    belongs_to :transactions, BlockchainAPI.Explorer.Transaction, type: :string, primary_key: true, foreign_key: :txn_hash, define_field: false

    timestamps()
  end

  @doc false
  def changeset(gateway, attrs) do
    gateway
    |> cast(attrs, [:owner, :gateway])
    |> validate_required([:owner, :gateway])
  end
end
