defmodule BlockchainAPI.Schema.PendingPayment do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.PendingPayment}
  @fields [:id, :hash, :status, :payer, :payee, :nonce, :fee, :amount, :type]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "pending_payments" do
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "pending"
    field :nonce, :integer, null: false, default: 0
    field :payer, :binary, null: false
    field :payee, :binary, null: false
    field :fee, :integer, null: false
    field :amount, :integer, null: false

    timestamps()
  end

  @doc false
  def changeset(pending_payment, attrs) do
    pending_payment
    |> cast(attrs, [:hash, :status, :payer, :payee, :nonce, :fee, :amount])
    |> validate_required([:hash, :status, :payer, :payee, :nonce, :fee, :amount])
    |> foreign_key_constraint(:payer)
    |> unique_constraint(:unique_pending_payment, name: :unique_pending_payment)
  end

  def encode_model(pending_payment) do
    %{
      Map.take(pending_payment, @fields) |
      payer: Util.bin_to_string(pending_payment.payer),
      payee: Util.bin_to_string(pending_payment.payee),
      hash: Util.bin_to_string(pending_payment.hash)
    }
  end

  defimpl Jason.Encoder, for: PendingPayment do
    def encode(pending_payment, opts) do
      pending_payment
      |> PendingPayment.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
