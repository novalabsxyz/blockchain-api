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

    embeds_one :path, Path do

      embeds_many :path_elements, PathElements do
        field :challengee, :binary, null: false

        embeds_one :receipt, Receipt do
          field :gateway, :binary, null: false
          field :timestamp, :integer, null: false
          field :signal, :integer, null: false
          field :data, :binary, null: false
          field :signature, :binary, null: false

          embeds_one :origin, Origin do
            field :p2p, :integer
            field :radio, :integer
          end
        end

        embeds_many :witnesses, Witnesses do
          field :gateway, :binary, null: false
          field :timestamp, :integer, null: false
          field :signal, :integer, null: false
          field :packet_hash, :binary, null: false
          field :signature, :binary, null: false
        end

      end
    end

    timestamps()
  end

  @doc false
  def changeset(poc_receipts, attrs) do
    poc_receipts
    |> cast(attrs, @fields)
    |> cast_embed(:path, with: &path_changeset/2)
    |> validate_required(@fields)
    |> foreign_key_constraint(:hash)
    |> foreign_key_constraint(:challenger)
  end

  defp path_changeset(schema, _attrs) do
    schema |> cast_embed(:path_elements, with: &path_elements_changeset/2)
  end

  defp path_elements_changeset(schema, attrs) do
    schema
    |> cast(attrs, [:challengee])
    |> cast_embed(:receipt, with: &receipt_changeset/2)
    |> cast_embed(:witnesses, with: &witnesses_changeset/2)
  end

  defp receipt_changeset(schema, attrs) do
    schema
    |> cast(attrs, [:gateway, :timestamp, :signal, :data, :signature])
    |> cast_embed(:origin, with: &origin_changeset/2)
  end

  defp origin_changeset(schema, attrs) do
    schema
    |> cast(attrs, [:p2p, :radio])
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
      path: :blockchain_txn_poc_receipts_v1.path(txn)
    }
  end
end
