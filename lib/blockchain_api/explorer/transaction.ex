defmodule BlockchainAPI.Explorer.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Explorer.Transaction}
  @fields [:id, :hash, :type, :block_height]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "transactions" do
    field :type, :string, null: false
    field :block_height, :integer, null: false
    field :hash, :binary, null: false

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:hash, :type, :block_height])
    |> validate_required([:hash, :type])
    |> unique_constraint(:hash)
    |> foreign_key_constraint(:block_height)
  end

  def encode_model(transaction) do
    %{
      Map.take(transaction, @fields) |
      hash: Util.bin_to_string(transaction.hash)
    }
  end

  defimpl Jason.Encoder, for: Transaction do
    def encode(transaction, opts) do
      transaction
      |> Transaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
