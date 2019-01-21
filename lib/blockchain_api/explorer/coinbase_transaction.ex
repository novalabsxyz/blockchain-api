defmodule BlockchainAPI.Explorer.CoinbaseTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:coinbase_hash, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :coinbase_hash}
  schema "coinbase_transactions" do
    field :amount, :integer
    field :payee, :string

    belongs_to :transactions, BlockchainAPI.Explorer.Transaction, foreign_key: :hash, define_field: false

    timestamps()
  end

  @doc false
  def changeset(coinbase, attrs) do
    coinbase
    |> cast(attrs, [:coinbase_hash, :amount, :payee, :coinbase_hash])
    |> validate_required([:coinbase_hash, :amount, :payee, :coinbase_hash])
    |> foreign_key_constraint(:coinbase_hash)
  end
end
