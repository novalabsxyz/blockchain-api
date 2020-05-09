defmodule BlockchainAPI.Schema.StateChannelOpenTxn do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.StateChannelOpenTxn}

  @fields [:id, :owner, :oui, :expire_within, :height, :time]

  @primary_key false
  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "state_channel_open_transactions" do
    field :id, :binary, null: false, primary_key: true
    field :hash, :binary, null: false
    field :oui, :integer, null: false
    field :owner, :binary, null: false
    field :nonce, :integer, null: false
    field :expire_within, :integer, null: false

    timestamps()
  end

  @doc false
  def changeset(txn, attrs) do
    txn
    |> cast(attrs, [:id, :hash, :oui, :owner, :nonce, :expire_within])
    |> validate_required([:id, :hash, :oui, :owner, :nonce, :expire_within])
    |> foreign_key_constraint(:hash)
  end

  def encode_model(state_channel_open_transaction) do
    state_channel_open_transaction
    |> Map.take(@fields)
    |> Map.merge(%{
      id: Util.bin_to_string(state_channel_open_transaction.id),
      owner: Util.bin_to_string(state_channel_open_transaction.owner),
      hash: Util.bin_to_string(state_channel_open_transaction.hash),
      type: "sc_open"
    })
  end

  defimpl Jason.Encoder, for: StateChannelOpenTxn do
    def encode(txn, opts) do
      txn
      |> StateChannelOpenTxn.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn) do
    %{
      id: :blockchain_txn_state_channel_open_v1.id(txn),
      owner: :blockchain_txn_state_channel_open_v1.owner(txn),
      oui: :blockchain_txn_state_channel_open_v1.oui(txn),
      nonce: :blockchain_txn_state_channel_open_v1.nonce(txn),
      expire_within: :blockchain_txn_state_channel_open_v1.expire_within(txn),
      hash: :blockchain_txn_state_channel_open_v1.hash(txn)
    }
  end
end
