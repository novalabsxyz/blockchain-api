defmodule BlockchainAPI.Schema.RewardTxn do
  use Ecto.Schema
  import Ecto.Changeset

  alias BlockchainAPI.{
    Util,
    Schema.RewardsTransaction,
    Schema.RewardTxn
  }

  @fields [
    :rewards_hash,
    :account,
    :gateway,
    :amount,
    :type
  ]

  @encoded_fields @fields ++ [:id]

  @derive {Jason.Encoder, only: @fields}
  schema "reward_txns" do
    field :account, :binary, null: false
    field :gateway, :binary, null: true
    field :amount, :integer, null: false
    field :rewards_hash, :binary, null: false
    field :type, :string, null: false

    belongs_to :rewards_transactions, RewardsTransaction, define_field: false, foreign_key: :hash

    timestamps()
  end

  @doc false
  def changeset(reward, attrs \\ %{}) do
    reward
    |> cast(attrs, @fields)
    |> validate_required([:account, :rewards_hash, :type, :amount])
    |> foreign_key_constraint(:rewards_hash)
  end

  def encode_model(reward) do
    reward
    |> Map.take(@encoded_fields)
    |> Map.merge(%{
      rewards_hash: Util.bin_to_string(reward.rewards_hash),
      account: Util.bin_to_string(reward.account),
      gateway: Util.bin_to_string(reward.gateway)
    })
  end

  def map(rewards_hash, reward_txn) do
    gateway =
      case :blockchain_txn_reward_v1.gateway(reward_txn) do
        :undefined -> nil
        gw -> gw
      end

    %{
      rewards_hash: rewards_hash,
      account: :blockchain_txn_reward_v1.account(reward_txn),
      gateway: gateway,
      amount: :blockchain_txn_reward_v1.amount(reward_txn),
      type: "#{Atom.to_string(:blockchain_txn_reward_v1.type(reward_txn))}_reward"
    }
  end

  defimpl Jason.Encoder, for: RewardTxn do
    def encode(reward, opts) do
      reward
      |> RewardTxn.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
