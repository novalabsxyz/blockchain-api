defmodule BlockchainAPI.Schema.ConsensusMember do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.ConsensusMember, Schema.ElectionTransaction}
  @fields [:address, :election_transactions_id]

  @derive {Jason.Encoder, only: @fields}
  schema "consensus_members" do
    field :address, :binary, null: false
    field :election_transactions_id, :integer, null: false

    belongs_to :election_transactions, ElectionTransaction, define_field: false, foreign_key: :id
    timestamps()
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:election_transactions_id)
  end

  def encode_model(member) do
    member
    |> Map.take(@fields)
    |> Map.merge(%{
      address: Util.bin_to_string(member.address)
    })
  end

  defimpl Jason.Encoder, for: ConsensusMember do
    def encode(member, opts) do
      member
      |> ConsensusMember.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(id, address) do
    %{
      election_transactions_id: id,
      address: address
    }
  end
end
