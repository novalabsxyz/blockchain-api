defmodule BlockchainAPI.Schema.POCReceiptsTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.POCReceiptsTransaction}

  @fields [:challenger, :hash, :signature, :fee, :onion]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "poc_receipts_transactions" do
    field :challenger, :binary, null: false
    field :hash, :binary, null: false
    field :signature, :binary, null: false
    field :fee, :integer, null: false
    field :onion, :binary, null: false

    embeds_many :path_elements, PathElements, primary_key: false do
      field :challengee, :string, null: false

      embeds_one :receipt, Receipt, primary_key: false do
        field :gateway, :string, null: false
        field :timestamp, :integer, null: false
        field :signal, :integer, null: false
        field :data, :string, null: false
        field :signature, :string, null: false
        field :origin, :string, null: false
      end

      embeds_many :witnesses, Witnesses, primary_key: false do
        field :gateway, :string, null: false
        field :timestamp, :integer, null: false
        field :signal, :integer, null: false
        field :packet_hash, :string, null: false
        field :signature, :string, null: false
      end

    end

    timestamps()
  end

  @doc false
  def changeset(poc_receipts, attrs) do
    poc_receipts
    |> cast(attrs, @fields)
    |> cast_embed(:path_elements, with: &path_elements_changeset/2)
    |> validate_required(@fields)
    |> foreign_key_constraint(:hash)
    |> foreign_key_constraint(:challenger)
  end

  defp path_elements_changeset(schema, attrs) do
    schema
    |> IO.inspect
    |> cast(attrs, [:challengee])
    |> IO.inspect
    |> cast_embed(:receipt, with: &receipt_changeset/2)
    |> cast_embed(:witnesses, with: &witnesses_changeset/2)
  end

  defp receipt_changeset(schema, attrs) do
    schema
    |> cast(attrs, [:gateway, :timestamp, :signal, :data, :signature, :origin])
  end

  defp witnesses_changeset(schema, attrs) do
    schema
    |> cast(attrs, [:gateway, :timestamp, :signal, :packet_hash, :signature])
  end

  def encode_model(poc_receipts) do
    %{
      Map.take(poc_receipts, @fields) |
      hash: Util.bin_to_string(poc_receipts.hash),
      challenger: Util.bin_to_string(poc_receipts.challenger),
      signature: Util.bin_to_string(poc_receipts.signature),
      onion: Util.bin_to_string(poc_receipts.onion)
    }
  end

  defimpl Jason.Encoder, for: POCReceiptsTransaction do
    def encode(poc_receipts, opts) do
      poc_receipts
      |> POCReceiptsTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(txn) do
    %{
      challenger: :blockchain_txn_poc_receipts_v1.challenger(txn),
      fee: :blockchain_txn_poc_receipts_v1.fee(txn),
      signature: :blockchain_txn_poc_receipts_v1.signature(txn),
      onion: :blockchain_txn_poc_receipts_v1.onion_key_hash(txn),
      hash: :blockchain_txn_poc_receipts_v1.hash(txn),
      path_elements: path_elements(:blockchain_txn_poc_receipts_v1.path(txn))
    }
  end

  defp path_elements([]), do: []
  defp path_elements(elements) do
    elements
    |> Enum.map(
      fn(path_element) ->
        %{
          challengee: Util.bin_to_string(:blockchain_poc_path_element_v1.challengee(path_element)),
          receipt: receipt(:blockchain_poc_path_element_v1.receipt(path_element)),
          witnesses: witnesses(:blockchain_poc_path_element_v1.witnesses(path_element))
        }
      end)
  end

  defp receipt(:undefined), do: %{}
  defp receipt(receipt) do
    %{
      gateway: Util.bin_to_string(:blockchain_poc_receipt_v1.gateway(receipt)),
      timestamp: :blockchain_poc_receipt_v1.timestamp(receipt),
      signal: :blockchain_poc_receipt_v1.signal(receipt),
      data: Base.encode64(:blockchain_poc_receipt_v1.data(receipt)),
      signature: Util.bin_to_string(:blockchain_poc_receipt_v1.signature(receipt)),
      origin: to_string(:blockchain_poc_receipt_v1.origin(receipt))
    }
  end

  defp witnesses([]), do: []
  defp witnesses(witnesses) do
    witnesses
    |> Enum.map(
      fn(witness) ->
        %{
          gateway: Util.bin_to_string(:blockchain_poc_witness_v1.gateway(witness)),
          timestamp: :blockchain_poc_witness_v1.timestamp(witness),
          signal: :blockchain_poc_witness_v1.signal(witness),
          packet_hash: Base.encode64(:blockchain_poc_witness_v1.packet_hash(witness)),
          signature: Util.bin_to_string(:blockchain_poc_witness_v1.signature(witness))
        }
      end
    )
  end
end
