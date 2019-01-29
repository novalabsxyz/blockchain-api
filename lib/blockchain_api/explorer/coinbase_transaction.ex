defmodule BlockchainAPI.Explorer.CoinbaseTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @derive {Phoenix.Param, key: :coinbase_hash}
  @derive {Poison.Encoder, only: [:id, :coinbase_hash, :amount, :payee]}
  schema "coinbase_transactions" do
    field :amount, :integer, null: false
    field :payee, :string, null: false
    field :coinbase_hash, :string, null: false

    belongs_to :transaction, BlockchainAPI.Explorer.Transaction, foreign_key: :hash, references: :hash, define_field: false

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
