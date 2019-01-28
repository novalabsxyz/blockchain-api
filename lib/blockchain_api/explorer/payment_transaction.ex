defmodule BlockchainAPI.Explorer.PaymentTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @derive {Phoenix.Param, key: :payment_hash}
  @derive {Poison.Encoder, only: [:id, :payment_hash, :amount, :fee, :nonce, :payee, :payer]}
  schema "payment_transactions" do
    field :amount, :integer, null: false
    field :fee, :integer, null: false
    field :nonce, :integer, null: false
    field :payee, :string, null: false
    field :payer, :string, null: false
    field :payment_hash, :string, null: false

    belongs_to :transaction, BlockchainAPI.Explorer.Transaction, foreign_key: :hash, references: :hash, define_field: false

    timestamps()
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:payment_hash, :amount, :payee, :payer, :fee, :nonce])
    |> validate_required([:payment_hash, :amount, :payee, :payer, :fee, :nonce])
    |> foreign_key_constraint(:payment_hash)
  end
end
