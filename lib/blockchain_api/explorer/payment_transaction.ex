defmodule BlockchainAPI.Explorer.PaymentTransaction do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:payment_hash, :string, autogenerate: false}
  schema "payment_transactions" do
    field :amount, :integer
    field :fee, :integer
    field :nonce, :integer
    field :payee, :string
    field :payer, :string

    belongs_to :transactions, BlockchainAPI.Explorer.Transaction, type: :string, primary_key: true, foreign_key: :txn_hash, define_field: false

    timestamps()
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:amount, :payee, :payer, :fee, :nonce])
    |> validate_required([:amount, :payee, :payer, :fee, :nonce])
  end
end
