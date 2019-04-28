defmodule BlockchainAPI.Schema.PendingCoinbase do
  use Ecto.Schema
  import Ecto.Changeset

  alias BlockchainAPI.{Util, Schema.PendingCoinbase}

  @fields [
    :payee,
    :hash,
    :status,
    :amount,
    :txn,
    :submit_height
  ]

  @submit_coinbase_queue :submit_coinbase_queue

  @derive {Jason.Encoder, only: @fields}
  schema "pending_coinbases" do
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "pending"
    field :amount, :integer, null: false, default: 0
    field :payee, :binary, null: false
    field :txn, :binary, null: false
    field :submit_height, :integer, null: false, default: 0

    timestamps()
  end

  @doc false
  def changeset(pending_coinbase, attrs) do
    pending_coinbase
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:unique_pending_coinbase, name: :unique_pending_coinbase)
  end

  def encode_model(pending_coinbase) do
    pending_coinbase
    |> Map.take(@fields)
    |> Map.drop([:txn, :submit_height])
    |> Map.merge(%{
      hash: Util.bin_to_string(pending_coinbase.hash),
      payee: Util.bin_to_string(pending_coinbase.payee),
      type: "coinbase"
    })
  end

  defimpl Jason.Encoder, for: PendingCoinbase do
    def encode(pending_coinbase, opts) do
      pending_coinbase
      |> PendingCoinbase.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn, submit_height) do
    %{
      hash: :blockchain_txn_coinbase_v1.hash(txn),
      amount: :blockchain_txn_coinbase_v1.amount(txn),
      status: "pending",
      payee: :blockchain_txn_coinbase_v1.payee(txn),
      txn: :blockchain_txn.serialize(txn),
      submit_height: submit_height
    }
  end

  def submit_coinbase_queue, do: @submit_coinbase_queue
end
