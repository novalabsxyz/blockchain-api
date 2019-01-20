defmodule BlockchainAPI.Explorer.CoinbaseTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:coinbase_hash, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :coinbase_hash}
  schema "coinbase_transactions" do
    field :amount, :integer
    field :payee, :string

    belongs_to :transactions, BlockchainAPI.Explorer.Transaction, type: :string, primary_key: true, foreign_key: :coinbase_hash, define_field: false

    timestamps()
  end

  @doc false
  def changeset(coinbase, attrs) do
    coinbase
    |> cast(attrs, [:amount, :payee, :coinbase_hash])
    |> validate_required([:amount, :payee, :coinbase_hash])
  end
end
