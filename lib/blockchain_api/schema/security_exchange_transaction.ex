defmodule BlockchainAPI.Schema.SecurityExchangeTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.SecurityExchangeTransaction}

  @required [
    :hash,
    :payer,
    :payee,
    :amount,
    :fee,
    :nonce,
    :signature,
    :status
  ]

  @fields [:id] ++ @required

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "security_exchange_transactions" do
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "cleared"
    field :amount, :integer, null: false
    field :payee, :binary, null: false
    field :fee, :integer, null: false
    field :payer, :binary, null: false
    field :signature, :binary, null: false
    field :nonce, :integer, null: false

    timestamps()
  end

  @doc false
  def changeset(security, attrs) do
    security
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> foreign_key_constraint(:hash)
  end

  def encode_model(security_exchange) do
    security_exchange
    |> Map.take(@fields)
    |> Map.merge(%{
      payee: Util.bin_to_string(security_exchange.payee),
      hash: Util.bin_to_string(security_exchange.hash),
      payer: Util.bin_to_string(security_exchange.payer),
      signature: Util.bin_to_string(security_exchange.signature),
      type: "security_exchange"
    })
  end

  defimpl Jason.Encoder, for: SecurityExchangeTransaction do
    def encode(security_exchange, opts) do
      security_exchange
      |> SecurityExchangeTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(security_exchange) do
    %{
      payee: :blockchain_txn_security_exchange_v1.payee(security_exchange),
      payer: :blockchain_txn_security_exchange_v1.payer(security_exchange),
      amount: :blockchain_txn_security_exchange_v1.amount(security_exchange),
      signature: :blockchain_txn_security_exchange_v1.signature(security_exchange),
      nonce: :blockchain_txn_security_exchange_v1.nonce(security_exchange),
      hash: :blockchain_txn_security_exchange_v1.hash(security_exchange),
      fee: :blockchain_txn_security_exchange_v1.fee(security_exchange)
    }
  end
end
