defmodule BlockchainAPI.Schema.DCTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.DCTransaction}
  @fields [:id, :hash, :amount, :payee, :height, :time]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "dc_transactions" do
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "cleared"
    field :amount, :integer, null: false
    field :payee, :binary, null: false

    timestamps()
  end

  @doc false
  def changeset(security, attrs) do
    security
    |> cast(attrs, [:hash, :amount, :payee, :status])
    |> validate_required([:hash, :amount, :payee, :status])
    |> foreign_key_constraint(:hash)
  end

  def encode_model(dc) do
    security
    |> Map.take(@fields)
    |> Map.merge(%{
      payee: Util.bin_to_string(dc.payee),
      hash: Util.bin_to_string(dc.hash),
      type: "dc"
    })
  end

  defimpl Jason.Encoder, for: SecurityTransaction do
    def encode(dc, opts) do
      dc
      |> DCTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(dc) do
    %{
      payee: :blockchain_txn_dc_coinbase_v1.payee(dc),
      amount: :blockchain_txn_dc_coinbase_v1.amount(dc),
      hash: :blockchain_txn_dc_coinbase_v1.hash(dc)
    }
  end
end
