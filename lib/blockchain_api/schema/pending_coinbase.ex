defmodule BlockchainAPI.Schema.PendingCoinbase do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.PendingCoinbase}
  @fields [:id, :payee, :hash, :status, :amount]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "pending_coinbases" do
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "pending"
    field :amount, :integer, null: false, default: 0
    field :payee, :binary, null: false

    timestamps()
  end

  @doc false
  def changeset(pending_coinbase, attrs) do
    pending_coinbase
    |> cast(attrs, [:hash, :status, :amount, :payee])
    |> validate_required([:hash, :status, :amount, :payee])
    |> unique_constraint(:unique_pending_coinbase, name: :unique_pending_coinbase)
  end

  def encode_model(pending_coinbase) do
    %{Map.take(pending_coinbase, @fields) |
      hash: Util.bin_to_string(pending_coinbase.hash),
      payee: Util.bin_to_string(pending_coinbase.payee)
    }
  end

  defimpl Jason.Encoder, for: PendingCoinbase do
    def encode(pending_coinbase, opts) do
      pending_coinbase
      |> PendingCoinbase.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
