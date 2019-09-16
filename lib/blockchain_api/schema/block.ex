defmodule BlockchainAPI.Schema.Block do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.Block, Schema.Transaction}
  @fields [:hash, :round, :time, :height]

  @derive {Phoenix.Param, key: :height}
  @derive {Jason.Encoder, only: @fields}
  schema "blocks" do
    field :hash, :binary, null: false
    field :round, :integer, null: false
    field :time, :integer, null: false
    field :height, :integer, null: false

    has_many :transactions, Transaction, foreign_key: :block_height, references: :height

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:hash, :height, :round, :time])
    |> validate_required([:hash, :height, :round, :time])
    |> unique_constraint(:height, name: :unique_block_height)
    |> unique_constraint(:time, name: :unique_block_time)
  end

  def encode_model(%{"hash" => hash, "round" => round, "time" => time, "height" => height}) do
    %{
      hash: Util.bin_to_string(hash),
      round: round,
      time: time,
      height: height
    }
  end

  def encode_model(block) do
    %{
      Map.take(block, @fields)
      | hash: Util.bin_to_string(block.hash)
    }
  end

  defimpl Jason.Encoder, for: Block do
    def encode(block, opts) do
      block
      |> Block.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map(block) do
    %{
      hash: :blockchain_block.hash_block(block),
      height: :blockchain_block.height(block),
      time: :blockchain_block.time(block),
      round: :blockchain_block.hbbft_round(block)
    }
  end
end
