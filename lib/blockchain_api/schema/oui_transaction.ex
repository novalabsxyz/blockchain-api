defmodule BlockchainAPI.Schema.OUITransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.OUITransaction}


  @required_fields [
    :hash,
    :owner,
    :addresses,
    :fee,
    :staking_fee,
    :status
  ]

  @fields [:payer, :id | @required_fields]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "oui_transactions" do
    field :hash, :binary, null: false
    field :owner, :binary, null: false
    field :addresses, {:array, :binary}, null: false, default: []
    field :payer, :binary, null: true # payer can be empty
    field :fee, :integer, null: false, default: 0
    field :staking_fee, :integer, null: false, default: 0
    field :status, :string, null: false, default: "cleared"

    timestamps()
  end

  @doc false
  def changeset(oui, attrs) do
    oui
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:hash)
  end

  def encode_model(oui) do
    oui
    |> Map.take(@fields)
    |> Map.merge(%{
      hash: Util.bin_to_string(oui.hash),
      payer: Util.bin_to_string(oui.payee),
      owner: Util.bin_to_string(oui.owner),
      addresses: Enum.map(fn(a) -> Util.bin_to_string(a) end, oui.addresses),
      type: "oui"
    })
  end

  defimpl Jason.Encoder, for: OUITransaction do
    def encode(oui, opts) do
      oui
      |> OUITransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn) do
    %{
      hash: :blockchain_txn_oui_v1.hash(txn),
      owner: :blockchain_txn_oui_v1.owner(txn),
      payer: :blockchain_txn_oui_v1.payer(txn),
      txn: :blockchain_txn.serialize(txn),
      addresses: :blockchain_txn_oui_v1.addresses(txn),
      staking_fee: :blockchain_txn_oui_v1.staking_fee(txn),
      fee: :blockchain_txn_oui_v1.fee(txn),
    }
  end
end
