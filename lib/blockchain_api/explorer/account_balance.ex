defmodule BlockchainAPI.Explorer.AccountBalance do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :account_address, :block_height, :block_time, :balance]}
  schema "account_transactions" do
    field :account_address, :string, null: false
    field :block_height, :integer, null: false
    field :block_time, :integer, null: false
    field :balance, :integer, null: false

    timestamps()
  end

  @doc false
  def changeset(account_balance, attrs) do
    account_balance
    |> cast(attrs, [:account_address, :block_height, :block_time, :balance])
    |> validate_required([:account_address, :block_height, :block_time, :balance])
    |> foreign_key_constraint(:address)
    |> foreign_key_constraint(:height)
    |> foreign_key_constraint(:time)
    |> unique_constraint(:unique_account_time_balance, name: :unique_account_time_balance)
  end
end
