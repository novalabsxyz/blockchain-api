defmodule BlockchainAPI.Schema.PendingPayment do
  use Ecto.Schema
  import Ecto.Changeset
  import Honeydew.EctoPollQueue.Schema
  alias BlockchainAPI.{Util, Schema.PendingPayment}

  @fields [
    :hash,
    :status,
    :payer,
    :payee,
    :nonce,
    :fee,
    :amount,
    :txn
  ]

  @submit_payment_queue :submit_payment_queue

  @derive {Jason.Encoder, only: @fields}
  schema "pending_payments" do
    field :amount, :integer, null: false
    field :fee, :integer, null: false
    field :nonce, :integer, null: false, default: 0
    field :payee, :binary, null: false
    field :payer, :binary, null: false
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "pending"
    field :txn, :binary, null: false

    honeydew_fields(@submit_payment_queue)

    timestamps()
  end

  @doc false
  def changeset(pending_payment, attrs) do
    pending_payment
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:payer)
    |> unique_constraint(:unique_pending_payment, name: :unique_pending_payment)
  end

  def encode_model(pending_payment) do
    pending_payment
    |> Map.take(@fields)
    |> Map.delete(:txn)
    |> Map.merge(%{
      payer: Util.bin_to_string(pending_payment.payer),
      payee: Util.bin_to_string(pending_payment.payee),
      hash: Util.bin_to_string(pending_payment.hash),
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

  def map(txn) do
    %{
      status: "pending",
      hash: :blockchain_txn_payment_v1.hash(txn),
      fee: :blockchain_txn_payment_v1.fee(txn),
      amount: :blockchain_txn_payment_v1.amount(txn),
      nonce: :blockchain_txn_payment_v1.nonce(txn),
      payer: :blockchain_txn_payment_v1.payer(txn),
      payee: :blockchain_txn_payment_v1.payee(txn),
      txn: :blockchain_txn.serialize(txn)
    }
  end

  def submit_payment_queue, do: @submit_payment_queue
end
