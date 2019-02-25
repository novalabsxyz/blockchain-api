defmodule BlockchainAPI.Explorer.PaymentTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Explorer.PaymentTransaction}
  @fields [:id, :hash, :amount, :fee, :nonce, :payee, :payer]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "payment_transactions" do
    field :amount, :integer, null: false
    field :fee, :integer, null: false
    field :nonce, :integer, null: false, default: 0
    field :payee, :binary, null: false
    field :payer, :binary, null: false
    field :hash, :binary, null: false

    timestamps()
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:hash, :amount, :payee, :payer, :fee, :nonce])
    |> validate_required([:hash, :amount, :payee, :payer, :fee, :nonce])
    |> foreign_key_constraint(:hash)
    |> unique_constraint(:unique_pending_payment, name: :unique_pending_payment)
  end

  def encode_model(payment) do
    %{
      Map.take(payment, @fields) |
      payer: Util.bin_to_string(payment.payer),
      payee: Util.bin_to_string(payment.payee),
      hash: Util.bin_to_string(payment.hash)
    }
  end

  defimpl Jason.Encoder, for: PaymentTransaction do
    def encode(payment, opts) do
      payment
      |> PaymentTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
