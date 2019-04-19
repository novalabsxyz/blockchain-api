defmodule BlockchainAPI.Schema.PendingPayment do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util,
    Schema.PendingPayment,
    Schema.PendingTransaction
  }

  @fields [
    :pending_transactions_hash,
    :status,
    :payer,
    :payee,
    :nonce,
    :fee,
    :amount]

  @derive {Jason.Encoder, only: @fields}
  schema "pending_payments" do
    field :amount, :integer, null: false
    field :fee, :integer, null: false
    field :nonce, :integer, null: false, default: 0
    field :payee, :binary, null: false
    field :payer, :binary, null: false
    field :pending_transactions_hash, :binary, null: false
    field :status, :string, null: false, default: "pending"

    belongs_to :pending_transactions, PendingTransaction, define_field: false, foreign_key: :hash

    timestamps()
  end

  @doc false
  def changeset(pending_payment, attrs) do
    pending_payment
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:payer)
    |> foreign_key_constraint(:pending_transactions_hash)
    |> unique_constraint(:unique_pending_payment, name: :unique_pending_payment)
  end

  def encode_model(pending_payment) do
    pending_payment
    |> Map.take(@fields)
    |> Map.merge(%{
      payer: Util.bin_to_string(pending_payment.payer),
      payee: Util.bin_to_string(pending_payment.payee),
      pending_transactions_hash: Util.bin_to_string(pending_payment.pending_transactions_hash),
      hash: Util.bin_to_string(pending_payment.pending_transactions_hash),
      type: "payment"
    })
  end

  defimpl Jason.Encoder, for: PendingPayment do
    def encode(pending_payment, opts) do
      pending_payment
      |> PendingPayment.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(hash, txn) do
    %{
      pending_transactions_hash: hash,
      status: "pending",
      fee: :blockchain_txn_payment_v1.fee(txn),
      amount: :blockchain_txn_payment_v1.amount(txn),
      nonce: :blockchain_txn_payment_v1.nonce(txn),
      payer: :blockchain_txn_payment_v1.payer(txn),
      payee: :blockchain_txn_payment_v1.payee(txn)
    }
  end

end
