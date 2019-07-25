defmodule BlockchainAPI.Schema.DataCreditTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.DataCreditTransaction}
  @fields [:id, :hash, :amount, :payee, :height, :time]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "data_credit_transactions" do
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

  def encode_model(data_credit) do
    security
    |> Map.take(@fields)
    |> Map.merge(%{
      payee: Util.bin_to_string(data_credit.payee),
      hash: Util.bin_to_string(data_credit.hash),
      type: "data_credit"
    })
  end

  defimpl Jason.Encoder, for: SecurityTransaction do
    def encode(data_credit, opts) do
      data_credit
      |> DataCreditTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(data_credit) do
    %{
      payee: :blockchain_txn_dc_coinbase_v1.payee(data_credit),
      amount: :blockchain_txn_dc_coinbase_v1.amount(data_credit),
      hash: :blockchain_txn_dc_coinbase_v1.hash(data_credit)
    }
  end
end
