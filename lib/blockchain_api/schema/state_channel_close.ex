defmodule BlockchainAPI.Schema.StateChannel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :id, :string, null: false
    field :owner, :string, null: false
    field :credits, :integer, null: false
    field :nonce, :integer, null: false
    embeds_many :balances, BlockchainAPI.Schema.StateChannel.Balance
    field :root_hash, :string
    field :state, :string, null: false
    field :expire_at_block, :integer
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:id, :owner, :credits, :nonce, :root_hash, :state, :expire_at_block])
    |> cast_embed(:balances)
  end

end

defmodule BlockchainAPI.Schema.StateChannel.Balance do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "balances" do
    field :hotspot, :string
    field :num_bytes, :integer
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:hotspot, :num_bytes])
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
    |> cast(attrs, [:closer, :hash])
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

    balances = sc0
               |> :blockchain_state_channel_v1.balances()
               |> Enum.map(
                 fn({h, b}) ->
                   %{hotspot: Util.bin_to_string(h), num_bytes: b}
                 end)

    sc = %{
      id: Util.bin_to_string(:blockchain_state_channel_v1.id(sc0)),
      owner: Util.bin_to_string(:blockchain_state_channel_v1.owner(sc0)),
      credits: :blockchain_state_channel_v1.credits(sc0),
      nonce: :blockchain_state_channel_v1.nonce(sc0),
      balances: balances,
      root_hash: Util.bin_to_string(:blockchain_state_channel_v1.root_hash(sc0)),
      state: Atom.to_string(:blockchain_state_channel_v1.state(sc0)),
      expire_at_block: :blockchain_state_channel_v1.expire_at_block(sc0)
    }

    %{
      closer: :blockchain_txn_state_channel_close_v1.closer(txn),
      hash: :blockchain_txn_state_channel_close_v1.hash(txn),
      state_channel: sc
    }
  end

end
