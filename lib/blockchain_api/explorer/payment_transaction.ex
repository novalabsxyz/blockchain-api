defmodule BlockchainAPI.Explorer.PaymentTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:payment_hash, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :payment_hash}
  schema "payment_transactions" do
    field :amount, :integer
    field :fee, :integer
    field :nonce, :integer
    field :payee, :string
    field :payer, :string
    # field :payment_hash, :string

    belongs_to :transactions, BlockchainAPI.Explorer.Transaction, foreign_key: :hash, references: :hash, define_field: false

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
