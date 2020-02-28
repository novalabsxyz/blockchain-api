defmodule BlockchainAPI.Schema.StateChannel do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :id, :binary
    field :owner, :binary
    field :credits, :integer
    field :nonce, :integer
    embeds_many :balances, BlockchainAPI.Schema.StateChannel.Balance
    field :root_hash, :binary
    field :state, :string
    field :expire_at_block, :integer
  end
end

defmodule BlockchainAPI.Schema.StateChannel.Balance do
  use Ecto.Schema

  @primary_key false
  schema "balances" do
    field :hotspot, :string, null: false
    field :num_bytes, :integer, nul: false
  end

end

defmodule BlockchainAPI.Schema.StateChannelCloseTxn do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.StateChannelCloseTxn}

  @fields [:closer, :state_channel]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "state_channel_close_transactions" do
    field :closer, :binary, null: false
    field :hash, :binary, null: false
    embeds_one :state_channel, BlockchainAPI.Schema.StateChannel

    timestamps()
  end

  @doc false
  def changeset(txn, attrs) do
    txn
    |> cast(attrs, [:closer])
    |> cast_embed(:state_channel)
    |> validate_required([:closer, :state_channel])
    |> foreign_key_constraint(:hash)
  end

  def encode_model(state_channel_close_transaction) do
    state_channel_close_transaction
    |> Map.take(@fields)
    |> Map.merge(%{
      closer: Util.bin_to_string(state_channel_close_transaction.closer),
      type: "state_channel_close"
    })
  end

  defimpl Jason.Encoder, for: StateChannelCloseTxn do
    def encode(txn, opts) do
      txn
      |> StateChannelCloseTxn.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn) do

    sc0 = :blockchain_txn_state_channel_close_v1.state_channel(txn)
    balances0 = :blockchain_state_channel_v1.balances(sc0)

    balances = Enum.map(balances0,
      fn {h, b} ->
        %BlockchainAPI.Schema.StateChannel.Balance{hotspot: h, num_bytes: b}
      end)

    sc = %BlockchainAPI.Schema.StateChannel{
      id: :blockchain_state_channel_v1.id(sc0),
      owner: :blockchain_state_channel_v1.owner(sc0),
      credits: :blockchain_state_channel_v1.credits(sc0),
      nonce: :blockchain_state_channel_v1.nonce(sc0),
      balances: balances,
      root_hash: :blockchain_state_channel_v1.root_hash(sc0),
      state: :blockchain_state_channel_v1.state(sc0),
      expire_at_block: :blockchain_state_channel_v1.expire_at_block(sc0)
    }

    %{
      closer: :blockchain_txn_state_channel_close_v1.closer(txn),
      hash: :blockchain_txn_state_channel_close_v1.hash(txn),
      state_channel: sc
    }
  end

end
