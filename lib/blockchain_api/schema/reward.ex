defmodule BlockchainAPI.Schema.Reward do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.Reward}
  @fields [:id, :block_height, :type, :account_address, :gateway_address, :amount]

  @derive {Jason.Encoder, only: @fields}
  schema "rewards" do
    field :block_height, :integer, null: false
    field :type, :string, null: false
    field :account_address, :binary, null: true
    field :gateway_address, :binary, null: true
    field :amount, :integer, null: false

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:block_height, :type, :amount, :account_address, :gateway_address])
    |> validate_required([:block_height, :type, :amount])
    |> foreign_key_constraint(:block_height)
  end

  def encode_model(reward) do
    %{
      Map.take(reward, @fields) |
      account_address: Util.bin_to_string(reward.account_address),
      gateway_address: Util.bin_to_string(reward.gateway_address)
    }
  end

  defimpl Jason.Encoder, for: Reward do
    def encode(reward, opts) do
      reward
      |> Reward.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
