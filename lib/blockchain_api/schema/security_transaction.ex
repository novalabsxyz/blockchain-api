defmodule BlockchainAPI.Schema.SecurityTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.SecurityTransaction}
  @fields [:id, :hash, :amount, :payee, :height, :time]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "security_transactions" do
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "cleared"
    field :amount, :integer, null: false
    field :payee, :binary, null: false

    timestamps()
  end

  @doc false
  def changeset(security, attrs) do
    security
    |> cast(attrs, [:hash, :amount, :payee, :hash, :status])
    |> validate_required([:hash, :amount, :payee, :hash, :status])
    # |> foreign_key_constraint(:hash)
  end

  def encode_model(security) do
    security
    |> Map.take(@fields)
    |> Map.merge(%{
      payee: Util.bin_to_string(security.payee),
      hash: Util.bin_to_string(security.hash),
      type: "security"
    })
  end

  defimpl Jason.Encoder, for: SecurityTransaction do
    def encode(security, opts) do
      security
      |> SecurityTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(security) do
    %{
      payee: :blockchain_txn_security_coinbase_v1.payee(security),
      amount: :blockchain_txn_security_coinbase_v1.amount(security),
      hash: :blockchain_txn_security_coinbase_v1.hash(security)
    }
  end
end
