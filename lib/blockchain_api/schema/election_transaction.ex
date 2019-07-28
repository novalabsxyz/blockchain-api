defmodule BlockchainAPI.Schema.ElectionTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.ElectionTransaction, Schema.ConsensusMember}
  @fields [:proof, :delay, :election_height, :hash]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "election_transactions" do
    field :hash, :binary, null: false
    # Proof is null for genesis block
    field :proof, :binary, null: true
    field :delay, :integer, null: false
    field :election_height, :integer, null: false

    has_many :consensus_members, ConsensusMember,
      foreign_key: :election_transactions_id,
      references: :id

    timestamps()
  end

  @doc false
  def changeset(election, attrs) do
    election
    |> cast(attrs, @fields)
    |> validate_required([:hash, :delay, :election_height])
    |> foreign_key_constraint(:hash)
  end

  def encode_model(election) do
    election
    |> Map.take(@fields)
    |> Map.merge(%{
      proof: Util.bin_to_string(election.proof),
      hash: Util.bin_to_string(election.hash),
      type: "election"
    })
  end

  defimpl Jason.Encoder, for: ElectionTransaction do
    def encode(election, opts) do
      election
      |> ElectionTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(election) do
    %{
      proof: :blockchain_txn_consensus_group_v1.proof(election),
      election_height: :blockchain_txn_consensus_group_v1.height(election),
      delay: :blockchain_txn_consensus_group_v1.delay(election),
      hash: :blockchain_txn_consensus_group_v1.hash(election)
    }
  end
end
