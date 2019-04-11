defmodule BlockchainAPI.Schema.POCPathElement do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{
    Util,
    Schema.POCPathElement,
    Schema.POCReceiptsTransaction,
    Schema.POCReceipt,
    Schema.POCWitness
  }

  @fields [:challengee, :challengee_loc, :poc_receipts_transactions_hash]

  @derive {Jason.Encoder, only: @fields}
  schema "poc_path_elements" do
    field :challengee, :binary, null: true
    field :challengee_loc, :string, null: true
    field :poc_receipts_transactions_hash, :binary, null: false

    belongs_to :poc_receipts_transactions, POCReceiptsTransaction, define_field: false, foreign_key: :hash
    has_many :poc_receipt, POCReceipt, foreign_key: :poc_path_elements_id, references: :id
    has_many :poc_witness, POCWitness, foreign_key: :poc_path_elements_id, references: :id

    timestamps()
  end

  @doc false
  def changeset(poc_path_element, attrs \\ %{}) do
    poc_path_element
    |> cast(attrs, @fields)
    |> foreign_key_constraint(:poc_receipts_transactions_hash)
  end

  def encode_model(poc_path_element) do
    {challengee, {lat, lng}} =
      case poc_path_element.challengee do
        "null" -> {nil, {nil, nil}}
        c ->
          {lat, lng} = Util.h3_to_lat_lng(poc_path_element.challengee_loc)
          {Util.bin_to_string(c), {lat, lng}}
      end

    poc_path_element
    |> Map.take(@fields)
    |> Map.merge(%{
      poc_receipts_transactions_hash: Util.bin_to_string(poc_path_element.poc_receipts_transactions_hash),
      challengee: challengee,
      challengee_lat: lat,
      challengee_lng: lng,
    })
  end

  def map(hash, challengee_loc, element) do
    %{
      poc_receipts_transactions_hash: hash,
      challengee: :blockchain_poc_path_element_v1.challengee(element),
      challengee_loc: Util.h3_to_string(challengee_loc),
    }
  end

  defimpl Jason.Encoder, for: POCPathElement do
    def encode(poc_path_element, opts) do
      poc_path_element
      |> POCPathElement.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
