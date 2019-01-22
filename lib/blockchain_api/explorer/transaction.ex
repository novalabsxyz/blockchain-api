defmodule BlockchainAPI.Explorer.Transaction do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:hash, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :hash}
  schema "transactions" do
    field :type, :string
    field :block_height, :integer

    belongs_to :blocks, BlockchainAPI.Explorer.Transaction, foreign_key: :height, define_field: false
    has_many :coinbase_transactions, BlockchainAPI.Explorer.CoinbaseTransaction, foreign_key: :coinbase_hash
    has_many :gateway_transactions, BlockchainAPI.Explorer.GatewayTransaction, foreign_key: :gateway_hash
    has_many :payment_transactions, BlockchainAPI.Explorer.PaymentTransaction, foreign_key: :payment_hash
    has_many :location_transactions, BlockchainAPI.Explorer.LocationTransaction, foreign_key: :location_hash

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:hash, :type, :block_height])
    |> validate_required([:hash, :type])
    |> unique_constraint(:hash)
    |> foreign_key_constraint(:block_height)
  end
end