defmodule BlockchainAPI.Schema.PendingOUI do
  use Ecto.Schema
  import Ecto.Changeset
  import Honeydew.EctoPollQueue.Schema

  alias BlockchainAPI.{Util, Schema.PendingOUI}

  @required [
    :hash,
    :owner,
    :addresses,
    :staking_fee,
    :fee,
    :txn,
    :submit_height,
    :status,
    :oui
  ]

  @fields [:payer | @required]

  @submit_oui_queue :submit_oui_queue

  @derive {Jason.Encoder, only: @fields}
  schema "pending_ouis" do
    field :hash, :binary, null: false
    field :owner, :binary, null: false
    field :addresses, {:array, :binary}, null: false, default: []
    field :payer, :binary, null: true # payer can be empty
    field :fee, :integer, null: false, default: 0
    field :staking_fee, :integer, null: false, default: 0
    field :oui, :integer, null: false, default: 1
    field :txn, :binary, null: false
    field :submit_height, :integer, null: false, default: 0
    field :status, :string, null: false, default: "pending"

    honeydew_fields(@submit_oui_queue)

    timestamps()
  end

  @doc false
  def changeset(pending_oui, attrs) do
    pending_oui
    |> cast(attrs, @fields)
    |> validate_required(@required)
  end

  def encode_model(pending_oui) do
    pending_oui
    |> Map.take(@fields)
    |> Map.drop([:txn, :submit_height])
    |> Map.merge(%{
      hash: Util.bin_to_string(pending_oui.hash),
      owner: Util.bin_to_string(pending_oui.owner),
      payer: Util.bin_to_string(pending_oui.payer),
      addresses: Enum.map(pending_oui.addresses, fn(a) -> Util.bin_to_string(a) end),
      type: "oui"
    })
  end

  defimpl Jason.Encoder, for: PendingOUI do
    def encode(pending_oui, opts) do
      pending_oui
      |> PendingOUI.encode_model()
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
      oui: :blockchain_txn_oui_v1.oui(txn),
      submit_height: submit_height,
      status: "pending"
    }
  end

  def submit_oui_queue, do: @submit_oui_queue
end
