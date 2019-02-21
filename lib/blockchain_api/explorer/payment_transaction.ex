defmodule BlockchainAPI.Explorer.PaymentTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: [:id, :hash, :amount, :fee, :nonce, :payee, :payer]}
  schema "payment_transactions" do
    field :amount, :integer, null: false
    field :fee, :integer, null: false
    field :nonce, :integer, null: false, default: 0
    field :payee, :string, null: false
    field :payer, :string, null: false
    field :hash, :string, null: false

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
end
