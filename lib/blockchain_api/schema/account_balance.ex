defmodule BlockchainAPI.Schema.AccountBalance do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Schema.AccountBalance, Util}
  @fields [:id, :account_address, :block_height, :block_time, :balance, :delta]

  @derive {Jason.Encoder, only: @fields}
  schema "account_balances" do
    field :account_address, :binary, null: false
    field :block_height, :integer, null: false
    field :block_time, :integer, null: false
    field :balance, :integer, null: false
    field :delta, :integer, null: false

    timestamps()
  end

  @doc false
  def changeset(account_balance, attrs) do
    account_balance
    |> cast(attrs, [:account_address, :block_height, :block_time, :balance, :delta])
    |> validate_required([:account_address, :block_height, :block_time, :balance, :delta])
    # |> unique_constraint(:unique_account_height_balance, name: :unique_account_height_balance)
  end

  def encode_model(account_balance) do
    %{
      Map.take(account_balance, @fields) |
      account_address: Util.bin_to_string(account_balance.address)
    }
  end

  defimpl Jason.Encoder, for: AccountBalance do
    def encode(account_balance, opts) do
      account_balance
      |> AccountBalance.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(address, balance, block, delta) do
    %{
      account_address: address,
      block_height: :blockchain_block.height(block),
      block_time: :blockchain_block.time(block),
      balance: balance,
      delta: delta
    }
  end
end
