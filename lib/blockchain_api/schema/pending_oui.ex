defmodule BlockchainAPI.Schema.PendingOui do
  use Ecto.Schema
  import Ecto.Changeset

  alias BlockchainAPI.{Util, Schema.PendingOui}

  @fields [
    :hash,
    :owner,
    :addresses,
    :payer,
    :staking_fee,
    :fee,
    :txn,
    :submit_height
  ]

  @submit_oui_queue :submit_oui_queue

  @derive {Jason.Encoder, only: @fields}
  schema "pending_ouis" do
    field :hash, :binary, null: false
    field :owner, :binary, null: false
    field :addresses, {:array, :binary}, null: false, default: []
    field :payer, :binary, null: false
    field :fee, :integer, null: false, default: 0
    field :staking_fee, :integer, null: false, default: 0
    field :txn, :binary, null: false
    field :submit_height, :integer, null: false, default: 0

    timestamps()
  end

  @doc false
  def changeset(pending_oui, attrs) do
    pending_oui
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end

  def encode_model(pending_oui) do
    pending_oui
    |> Map.take(@fields)
    |> Map.drop([:txn, :submit_height])
    |> Map.merge(%{
      hash: Util.bin_to_string(pending_oui.hash),
      owner: Util.bin_to_string(pending_oui.owner),
      payer: Util.bin_to_string(pending_oui.payer),
      addresses: Enum.map(fn(a) -> Util.bin_to_string(a) end, pending_oui.addresses),
      type: "oui"
    })
  end

  defimpl Jason.Encoder, for: PendingOui do
    def encode(pending_oui, opts) do
      pending_oui
      |> PendingOui.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn, submit_height) do
    %{
      hash: :blockchain_txn_oui_v1.hash(txn),
      owner: :blockchain_txn_oui_v1.owner(txn),
      payer: :blockchain_txn_oui_v1.payer(txn),
      txn: :blockchain_txn.serialize(txn),
      addresses: :blockchain_txn_oui_v1.addresses(txn),
      staking_fee: :blockchain_txn_oui_v1.staking_fee(txn),
      fee: :blockchain_txn_oui_v1.fee(txn),
      submit_height: submit_height,
      status: "pending"
    }
  end

  def submit_oui_queue, do: @submit_oui_queue
end
