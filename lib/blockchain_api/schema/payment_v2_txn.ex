defmodule BlockchainAPI.Schema.PaymentV2Txn do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.PaymentV2Txn}
  @fields [:id, :hash, :fee, :nonce, :payer, :payments, :height, :time]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "payment_v2_txns" do
    field :fee, :integer, null: false
    field :nonce, :integer, null: false, default: 0
    field :payer, :binary, null: false
    embeds_many :payments, BlockchainAPI.Schema.Payment
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "cleared"

    timestamps()
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:hash, :payer, :fee, :nonce, :status])
    |> cast_embed(:payments)
    |> validate_required([:hash, :payer, :payments, :fee, :nonce, :status])
    |> foreign_key_constraint(:hash)
  end

  def encode_model(payment) do
    payment
    |> Map.take(@fields)
    |> Map.merge(%{
      payer: Util.bin_to_string(payment.payer),
      hash: Util.bin_to_string(payment.hash),
      type: "payment_v2"
    })
  end

  defimpl Jason.Encoder, for: PaymentV2Txn do
    def encode(payment, opts) do
      payment
      |> PaymentV2Txn.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn) do

    payments = txn
               |> :blockchain_txn_payment_v2.payments()
               |> Enum.map(
                 fn(payment) ->
                   %{payee: Util.bin_to_string(:blockchain_payment_v2.payee(payment)),
                     amount: :blockchain_payment_v2.amount(payment)
                   }
                 end)

    %{
      payer: :blockchain_txn_payment_v2.payer(txn),
      payments: payments,
      nonce: :blockchain_txn_payment_v2.nonce(txn),
      fee: :blockchain_txn_payment_v2.fee(txn),
      hash: :blockchain_txn_payment_v2.hash(txn)
    }
  end
end

defmodule BlockchainAPI.Schema.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [:payee, :amount]

  @derive {Jason.Encoder, only: @fields}
  @primary_key false
  schema "payments" do
    field :payee, :string
    field :amount, :integer
  end

  def changeset(schema, params) do
    schema |> cast(params, [:payee, :amount])
  end

end
