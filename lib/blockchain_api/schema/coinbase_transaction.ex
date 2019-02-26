defmodule BlockchainAPI.Schema.CoinbaseTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.CoinbaseTransaction}
  @fields [:id, :hash, :amount, :payee]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "coinbase_transactions" do
    field :amount, :integer, null: false
    field :payee, :binary, null: false
    field :hash, :binary, null: false

    timestamps()
  end

  @doc false
  def changeset(coinbase, attrs) do
    coinbase
    |> cast(attrs, [:hash, :amount, :payee, :hash])
    |> validate_required([:hash, :amount, :payee, :hash])
    |> foreign_key_constraint(:hash)
  end

  def encode_model(coinbase) do
    %{Map.take(coinbase, @fields) |
      payee: Util.bin_to_string(coinbase.payee),
      hash: Util.bin_to_string(coinbase.hash)
    }
  end

  defimpl Jason.Encoder, for: CoinbaseTransaction do
    def encode(coinbase, opts) do
      coinbase
      |> CoinbaseTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(coinbase) do
    %{
      payee: :blockchain_txn_coinbase_v1.payee(coinbase),
      amount: :blockchain_txn_coinbase_v1.amount(coinbase)
    }
  end
end
