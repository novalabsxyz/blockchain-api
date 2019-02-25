defmodule BlockchainAPI.Explorer.Block do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Explorer.Block}
  @fields [:hash, :round, :time, :height]

  @derive {Phoenix.Param, key: :height}
  @derive {Jason.Encoder, only: @fields}
  schema "blocks" do
    field :hash, :binary, null: false
    field :round, :integer, null: false
    field :time, :integer, null: false
    field :height, :integer, null: false

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:hash, :height, :round, :time])
    |> validate_required([:hash, :height, :round, :time])
    |> unique_constraint(:hash)
    |> unique_constraint(:height)
  end

  def encode_model(block) do
    %{
      Map.take(block, @fields) |
      hash: Util.bin_to_string(block.hash)
    }
  end

  defimpl Jason.Encoder, for: Block do
    def encode(block, opts) do
      block
      |> Block.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
