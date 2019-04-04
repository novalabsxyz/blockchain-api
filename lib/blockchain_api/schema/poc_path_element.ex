defmodule BlockchainAPI.Schema.POCPathElement do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.POCPathElement}

  @fields [:challengee, :poc_receipts_transactions_hash]

  @derive {Jason.Encoder, only: @fields}
  schema "poc_path_elements" do
    field :challengee, :binary, null: true
    field :poc_receipts_transactions_hash, :binary, null: false

    timestamps()
  end

  @doc false
  def changeset(poc_path_element, attrs \\ %{}) do
    poc_path_element
    |> cast(attrs, @fields)
    |> foreign_key_constraint(:poc_receipts_transactions_hash)
  end

  def encode_model(poc_path_element) do
    challengee =
      case poc_path_element.challengee do
        "null" -> "null"
        c -> Util.bin_to_string(c)
      end
    @fields
    |> Map.take(poc_path_element)
    |> Map.merge(%{
      poc_receipts_transaction_hash: Util.bin_to_string(poc_path_element.poc_receipts_transaction_hash),
      challengee: challengee
    })
  end

  def map(hash, element) do
    %{
      poc_receipts_transactions_hash: hash,
      challengee: :blockchain_poc_path_element_v1.challengee(element)
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
