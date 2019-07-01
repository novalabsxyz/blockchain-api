defmodule BlockchainAPI.Schema.PaymentTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.PaymentTransaction}
  @fields [:id, :hash, :amount, :fee, :nonce, :payee, :payer, :height, :time]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "payment_transactions" do
    field :amount, :integer, null: false
    field :fee, :integer, null: false
    field :nonce, :integer, null: false, default: 0
    field :payee, :binary, null: false
    field :payer, :binary, null: false
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "cleared"

    timestamps()
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:hash, :amount, :payee, :payer, :fee, :nonce, :status])
    |> validate_required([:hash, :amount, :payee, :payer, :fee, :nonce, :status])
    # |> foreign_key_constraint(:hash)
    |> unique_constraint(:unique_pending_payment, name: :unique_pending_payment)
  end

  def encode_model(payment) do
    payment
    |> Map.take(@fields)
    |> Map.merge(%{
      payer: Util.bin_to_string(payment.payer),
      payee: Util.bin_to_string(payment.payee),
      hash: Util.bin_to_string(payment.hash),
      type: "payment"
    })
  end

  defimpl Jason.Encoder, for: PaymentTransaction do
    def encode(payment, opts) do
      payment
      |> PaymentTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn) do
    %{
      payee: :blockchain_txn_payment_v1.payee(txn),
      payer: :blockchain_txn_payment_v1.payer(txn),
      amount: :blockchain_txn_payment_v1.amount(txn),
      nonce: :blockchain_txn_payment_v1.nonce(txn),
      fee: :blockchain_txn_payment_v1.fee(txn),
      hash: :blockchain_txn_payment_v1.hash(txn)
    }
  end
end
