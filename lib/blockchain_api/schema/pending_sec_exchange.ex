defmodule BlockchainAPI.Schema.PendingSecExchange do
  use Ecto.Schema
  import Ecto.Changeset
  import Honeydew.EctoPollQueue.Schema

  alias BlockchainAPI.{Util, Schema.PendingSecExchange}

  @fields [
    :hash,
    :amount,
    :payee,
    :payer,
    :fee,
    :nonce,
    :signature,
    :status,
    :txn,
    :submit_height
  ]

  @submit_sec_exchange_queue :submit_sec_exchange_queue

  @derive {Jason.Encoder, only: @fields}
  schema "pending_sec_exchanges" do
    field :hash, :binary, null: false
    field :amount, :integer, null: false
    field :payee, :binary, null: false
    field :payer, :binary, null: false
    field :fee, :integer, null: false, default: 0
    field :nonce, :integer, null: false, default: 1
    field :signature, :binary, null: false
    field :txn, :binary, null: false
    field :submit_height, :integer, null: false, default: 0
    field :status, :string, null: false, default: "pending"

    honeydew_fields(@submit_sec_exchange_queue)

    timestamps()
  end

  @doc false
  def changeset(pending_sec_exchange, attrs) do
    pending_sec_exchange
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end

  def encode_model(pending_sec_exchange) do
    pending_sec_exchange
    |> Map.take(@fields)
    |> Map.drop([:txn, :submit_height])
    |> Map.merge(%{
      hash: Util.bin_to_string(pending_sec_exchange.hash),
      owner: Util.bin_to_string(pending_sec_exchange.owner),
      payer: Util.bin_to_string(pending_sec_exchange.payer),
      payee: Util.bin_to_string(pending_sec_exchange.payee),
      signature: Util.bin_to_string(pending_sec_exchange.signature),
      type: "security_exchange"
    })
  end

  defimpl Jason.Encoder, for: PendingSecExchange do
    def encode(pending_sec_exchange, opts) do
      pending_sec_exchange
      |> PendingSecExchange.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn, submit_height) do
    %{
      hash: :blockchain_txn_security_exchange_v1.hash(txn),
      amount: :blockchain_txn_security_exchange_v1.amount(txn),
      payee: :blockchain_txn_security_exchange_v1.payee(txn),
      payer: :blockchain_txn_security_exchange_v1.payer(txn),
      fee: :blockchain_txn_security_exchange_v1.fee(txn),
      nonce: :blockchain_txn_security_exchange_v1.nonce(txn),
      signature: :blockchain_txn_security_exchange_v1.signature(txn),
      txn: :blockchain_txn.serialize(txn),
      submit_height: submit_height,
      status: "pending"
    }
  end

  def submit_sec_exchange_queue, do: @submit_sec_exchange_queue
end

