defmodule BlockchainAPI.Explorer.PendingPayment do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: [:id, :hash, :status, :payer, :payee, :nonce, :fee]}
  schema "pending_payments" do
    field :hash, :string, null: false
    field :status, :string, null: false, default: "pending"
    field :nonce, :integer, null: false, default: 0
    field :payer, :string, null: false
    field :payee, :string, null: false
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
end
