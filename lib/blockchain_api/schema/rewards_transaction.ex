defmodule BlockchainAPI.Schema.RewardsTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.RewardsTransaction, Schema.RewardTxn}
  @fields [:id, :hash, :fee, :epoch]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "rewards_transactions" do
    field :hash, :binary, null: false
    field :fee, :integer, null: false
    field :epoch, :integer, null: false

    has_many :reward_txns, RewardTxn, foreign_key: :rewards_hash, references: :hash

    timestamps()
  end

  @doc false
  def changeset(rewards, attrs) do
    rewards
    |> cast(attrs, [:hash, :fee, :epoch])
    |> validate_required([:hash, :fee, :epoch])
    |> foreign_key_constraint(:hash)
  end

  def encode_model(rewards) do
    rewards
    |> Map.take(@fields)
    |> Map.merge(%{
      hash: Util.bin_to_string(rewards.hash),
      type: "rewards"
    })
  end

  defimpl Jason.Encoder, for: RewardsTransaction do
    def encode(rewards, opts) do
      rewards
      |> RewardsTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(rewards_txn) do
    %{
      fee: :blockchain_txn_rewards_v1.fee(rewards_txn),
      hash: :blockchain_txn_rewards_v1.hash(rewards_txn),
      epoch: :blockchain_txn_rewards_v1.epoch(rewards_txn)
    }
  end
end
