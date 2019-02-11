defmodule BlockchainAPI.Explorer.CoinbaseTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: [:id, :hash, :amount, :payee]}
  schema "coinbase_transactions" do
    field :amount, :integer, null: false
    field :payee, :string, null: false
    field :hash, :string, null: false

    belongs_to :transaction, BlockchainAPI.Explorer.Transaction, foreign_key: :hash, references: :hash, define_field: false

    timestamps()
  end

  @doc false
  def changeset(coinbase, attrs) do
    coinbase
    |> cast(attrs, [:hash, :amount, :payee, :hash])
    |> validate_required([:hash, :amount, :payee, :hash])
    |> foreign_key_constraint(:hash)
  end
end
